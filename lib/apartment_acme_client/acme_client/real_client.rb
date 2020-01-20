# frozen_string_literal: true

require 'acme-client'

module ApartmentAcmeClient
  module AcmeClient
    class RealClient
      attr_reader :csr_private_key
      def initialize(acme_client_private_key:, csr_private_key:)
        @client = Acme::Client.new(
          private_key: acme_client_private_key,
          directory: server_directory
        )
        @csr_private_key = csr_private_key
      end

      def register(email)
        # If the private key is not known to the server, we need to register it for the first time.
        account = @client.new_account(contact: "mailto:#{email}", terms_of_service_agreed: true)
        Rollbar.notice("New Let's Encrypt Account created with KID: #{account.kid}")

        true
      end

      def authorize(domain:)
        @client.authorize(domain: domain)
      end

      # Create a Certificate for our new set of domain names
      # returns that certificate
      def request_certificate(common_name:, names:, order:)
        # We're going to need a certificate signing request. If not explicitly
        # specified, the first name listed becomes the common name.
        csr = Acme::Client::CertificateRequest.new(private_key: csr_private_key, subject: { common_name: common_name, names: names })
        order.finalize(csr: csr)
        while order.status == 'processing'
          sleep(1)
          order.reload
        end

        order.certificate
      end

      private

      def server_directory
        # We need an ACME server to talk to, see github.com/letsencrypt/boulder
        # WARNING: This endpoint is the production endpoint, which is rate limited and will produce valid certificates.
        # You should probably use the staging endpoint for all your experimentation:
        if ApartmentAcmeClient.lets_encrypt_test_server_enabled
          'https://acme-staging-v02.api.letsencrypt.org/directory'
        else
          'https://acme-v02.api.letsencrypt.org/directory'
        end
      end
    end
  end
end
