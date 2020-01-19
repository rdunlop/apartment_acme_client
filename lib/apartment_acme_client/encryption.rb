require 'openssl'

# Initially, the system is only accessible via subdomain.example.com
# But, as we add more Conventions, we want to be able to access those also,
# thus we will need:
# - a.subdomain.example.com
# - b.subdomain.example.com
# - c.subdomain.example.com
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
  class Encryption
    def initialize
      @certificate_storage = ApartmentAcmeClient::CertificateStorage::Proxy.singleton
    end

    # Largely based on https://github.com/unixcharles/acme-client documentation
    def register_new(email)
      raise StandardError.new("Private key already exists") unless @certificate_storage.private_key.nil?

      private_key = create_private_key

      # Initialize the client
      new_client = ApartmentAcmeClient::AcmeClient::Proxy.singleton(
        private_key: private_key,
      )

      new_client.register(email)

      @certificate_storage.save_private_key(private_key)
    end

    def authorize_domains(domains)
      successful_domains = domains.select { |domain| authorize_domain(domain) }
      successful_domains
    end

    # authorizes a domain with letsencrypt server
    # returns true on success, false otherwise.
    #
    # from https://github.com/unixcharles/acme-client/tree/master#authorize-for-domain
    def authorize_domain(domain)
      authorization = client.authorize(domain: domain)

      # This example is using the http-01 challenge type. Other challenges are dns-01 or tls-sni-01.
      challenge = authorization.http01

      # The http-01 method will require you to respond to a HTTP request.

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
      challenge.request_verification # => true

      success = false
      10.times do
        if challenge.verify_status == 'valid' # may be 'pending' initially
          success = true
          break
        end

        # Wait a bit for the server to make the request, or just blink. It should be fast.
        sleep(1)
      end
      File.delete(full_challenge_filename)

      success
    end

    def request_certificate(common_name:, domains:)
      client.request_certificate(common_name: common_name, domains: domains)
    end

    private

    def client
      @client ||= ApartmentAcmeClient::AcmeClient::Proxy.singleton(
        private_key: private_key,
      )
    end

    # Returns a private key
    def private_key
      private_key = @certificate_storage.private_key
      return nil unless private_key

      OpenSSL::PKey::RSA.new(private_key)
    end

    def create_private_key
      OpenSSL::PKey::RSA.new(4096)
    end
  end
end
