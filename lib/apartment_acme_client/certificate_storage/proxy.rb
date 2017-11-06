module ApartmentAcmeClient
  module CertificateStorage
    TEST_PREFIX = "test_".freeze

    class Proxy
      def self.singleton
        base_class.new
      end

      def self.base_class
        ApartmentAcmeClient.certificate_storage_class || CertificateStorage::S3
      end
    end
  end
end
