module ApartmentAcmeClient
  module AcmeClient
    class Proxy
      def self.singleton(options = {})
        base_class.new(options)
      end

      def self.base_class
        # allow overriding the AcmeClient
        ApartmentAcmeClient.acme_client_class || AcmeClient::RealClient
      end
    end
  end
end
