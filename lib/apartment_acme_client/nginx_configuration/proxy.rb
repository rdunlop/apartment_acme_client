module ApartmentAcmeClient
  module NginxConfiguration
    class Proxy
      def self.singleton
        base_class.new
      end

      def self.base_class
        ApartmentAcmeClient.nginx_configuration_class || NginxConfiguration::Real
      end
    end
  end
end
