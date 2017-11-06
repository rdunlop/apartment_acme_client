require 'acme-client'

module ApartmentAcmeClient
  module AcmeClient
    class RealClient
      def initialize(private_key:)
        @client = Acme::Client.new(
          private_key: private_key,
          endpoint: server_endpoint,
        )
      end

      def register(email)
        # If the private key is not known to the server, we need to register it for the first time.
        registration = @client.register(contact: "mailto:#{email}")

        # You may need to agree to the terms of service (that's up the to the server to require it or not but boulder does by default)
        registration.agree_terms

        true
      end

      def authorize(domain:)
        @client.authorize(domain: domain)
      end

      # Create a Certificate for our new set of domain names
      # returns that certificate
      def request_certificate(common_name:, domains:)
        # We're going to need a certificate signing request. If not explicitly
        # specified, the first name listed becomes the common name.
        csr = Acme::Client::CertificateRequest.new(common_name: common_name, names: domains)

        # We can now request a certificate. You can pass anything that returns
        # a valid DER encoded CSR when calling to_der on it. For example an
        # OpenSSL::X509::Request should work too.
        certificate = @client.new_certificate(csr) # => #<Acme::Client::Certificate ....>

        certificate
      end

      private

      def server_endpoint
        # We need an ACME server to talk to, see github.com/letsencrypt/boulder
        # WARNING: This endpoint is the production endpoint, which is rate limited and will produce valid certificates.
        # You should probably use the staging endpoint for all your experimentation:
        if ApartmentAcmeClient.lets_encrypt_test_server_enabled
          'https://acme-staging.api.letsencrypt.org/'
        else
          'https://acme-v01.api.letsencrypt.org/'
        end
      end
    end
  end
end
