# frozen_string_literal: true

require 'openssl'

# Initially, the system is only accessible via subdomain.example.com
# But, as we add more Conventions, we want to be able to access those also,
# thus we will need:
# - *.subdomain.example.com
#
# Also, each convention may add an "alias" for their convention, like:
# - www.naucc.com
# - french-convention.unicycle.fr
#
# Steps to make this work:
# 1) When a new Convention is created, or a new alias is added, configure nginx
#    so that it responds to that domain request
#    `rake update_nginx_config` (writes a new nginx.conf and restarts nginx)
#
# 2) Register the new domain with letsencrypt
#    `rake renew_and_update_certificate`
#
# Manage the encryption of the website (https).
module ApartmentAcmeClient
  class Encryption # rubocop:disable Metrics/ClassLength
    def initialize
      @certificate_storage = ApartmentAcmeClient::CertificateStorage::Proxy.singleton
    end

    # Largely based on https://github.com/unixcharles/acme-client documentation
    def register_new(email)
      raise StandardError.new('Private key already exists') unless @certificate_storage.private_key.nil?

      private_key = create_private_key

      # Initialize the client
      new_client = ApartmentAcmeClient::AcmeClient::Proxy.singleton(
        acme_client_private_key: private_key,
        csr_private_key: nil, # not needed for 'register' call
      )

      new_client.register(email)

      @certificate_storage.save_private_key(private_key)
    end

    # Authorize a wildcard cert domain.
    # to do this, we have to write to the Amazon Route53 DNS entry
    # params:
    #  - authorizations - a list of authorizations, which may be http or dns based (ignore the non-wildcard ones)
    #  - wildcard_domain - the url of the wildcard's base domain (e.g. "site.example.com")
    def authorize_domains_with_dns(authorizations, wildcard_domain:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      label = nil
      record_type = nil
      values = []

      dns_authorizations = []
      authorizations.each do |domain_authorization|
        next unless domain_authorization.wildcard || domain_authorization.http.nil?

        dns_authorizations << domain_authorization.dns
      end

      dns_authorizations.each do |authorization|
        label         = "#{authorization.record_name}.#{wildcard_domain}"
        record_type   = authorization.record_type
        value         = authorization.record_content
        values << value
      end

      return true unless values.any?

      route53 = ApartmentAcmeClient::DnsApi::Route53.new(
        requested_domain: wildcard_domain,
        dns_record_label: label,
        record_type: record_type,
        values: values
      )

      puts "writing #{label} to Route53"
      route53.write_record

      check_dns = ApartmentAcmeClient::DnsApi::CheckDns.new(wildcard_domain, label)

      check_dns.wait_for_present(values.first)
      puts "waiting 60 seconds before requesting DNS check from LetsEncrypt"
      sleep(60)

      if check_dns.check_dns(values.first)
        # DNS is updated, proceed with cert request
        dns_authorizations.each do |domain_authorization|
          domain_authorization.request_validation

          60.times do
            # may be 'pending' initially
            break if domain_authorization.status == 'valid'

            puts "Waiting for LetsEncrypt to authorize the domain. Status #{domain_authorization.status}"

            # Wait a bit for the server to make the request, or just blink. It should be fast.
            sleep(2)
            domain_authorization.reload
          end
        end
      else
        # ERROR, DNS not updated in time
        Rollbar.error("DNS Entry not found in timeout")
      end
    end

    # authorizes a single domain with letsencrypt server
    # returns true on success, false otherwise.
    #
    # from https://github.com/unixcharles/acme-client/tree/master#authorize-for-domain
    def authorize_domain_with_http(domain_authorization) # rubocop:disable Metrics/MethodLength
      challenge = domain_authorization.http

      puts "authorizing Domain: #{domain_authorization.domain}"
      # The http method will require you to respond to a HTTP request.

      # You can retrieve the challenge token
      challenge.token # => "some_token"

      # You can retrieve the expected path for the file.
      challenge.filename # => ".well-known/acme-challenge/:some_token"

      # You can generate the body of the expected response.
      challenge.file_content # => 'string token and JWK thumbprint'

      # You are not required to send a Content-Type. This method will return the right Content-Type should you decide to include one.
      challenge.content_type

      # Save the file. We'll create a public directory to serve it from, and inside it we'll create the challenge file.
      FileUtils.mkdir_p(File.join(ApartmentAcmeClient.public_folder, File.dirname(challenge.filename)))

      # We'll write the content of the file
      full_challenge_filename = File.join(ApartmentAcmeClient.public_folder, challenge.filename)
      File.write(full_challenge_filename, challenge.file_content)

      # Optionally save the challenge for use at another time (eg: by a background job processor)
      #  File.write('challenge', challenge.to_h.to_json)

      # The challenge file can be served with a Ruby webserver.
      # You can run a webserver in another console for that purpose. You may need to forward ports on your router.
      #
      # $ ruby -run -e httpd public -p 8080 --bind-address 0.0.0.0

      # Load a saved challenge. This is only required if you need to reuse a saved challenge as outlined above.
      #  challenge = client.challenge_from_hash(JSON.parse(File.read('challenge')))

      # Once you are ready to serve the confirmation request you can proceed.
      challenge.request_validation # => true

      30.times do
        # may be 'pending' initially
        if challenge.status == 'valid'
          puts "authorized!"
          break
        end

        puts "Waiting for letsencrypt to authorize the single domain. Status: #{challenge.status}"

        # Wait a bit for the server to make the request, or just blink. It should be fast.
        sleep(2)
        challenge.reload
      end
      File.delete(full_challenge_filename)

      challenge.status == 'valid'
    end

    # Create an order, perform authorization for each domain, and then
    # request the certificate.
    # - common name is used so that there is continuity of requests over time
    # - domains are the list of individual http-based domains to be authorized
    # - wildcard_domain is an optional wildcard domain to be authorized via DNS Record
    #
    # Returns the certificate
    def request_certificate(common_name:, domains:, wildcard_domain: nil)
      domain_names_requested = domains
      domain_names_requested += [wildcard_domain, "*.#{wildcard_domain}"] if wildcard_domain.present?
      order = client.new_order(identifiers: domain_names_requested)

      # Do the HTTP authorizations
      order.authorizations.each do |authorization|
        next if authorization.wildcard || authorization.http.nil?

        authorize_domain_with_http(authorization)
      end

      # Do the DNS (wildcard) authorizations
      if authorize_domains_with_dns(order.authorizations, wildcard_domain: wildcard_domain)
        client.request_certificate(common_name: common_name, names: domain_names_requested, order: order)
      else # rubocop:disable Style/EmptyElse
        # error, not authorized
        nil
      end
    end

    # for use in order to store this on the machine for NGINX use
    def csr_private_key_string
      csr_private_key.to_s
    end

    private

    def client
      @client ||= ApartmentAcmeClient::AcmeClient::Proxy.singleton(
        acme_client_private_key: acme_client_private_key,
        csr_private_key: csr_private_key,
      )
    end

    # Returns a private key
    def acme_client_private_key
      private_key = @certificate_storage.private_key
      return nil unless private_key

      OpenSSL::PKey::RSA.new(private_key)
    end

    def csr_private_key
      private_key = @certificate_storage.csr_private_key

      # create a new private key if one is not found
      if private_key.nil?
        private_key = create_private_key
        @certificate_storage.save_csr_private_key(private_key)
      end

      OpenSSL::PKey::RSA.new(private_key)
    end

    def create_private_key
      OpenSSL::PKey::RSA.new(4096)
    end
  end
end
