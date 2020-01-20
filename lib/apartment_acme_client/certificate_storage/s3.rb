# frozen_string_literal: true

require 'aws-sdk-s3'

module ApartmentAcmeClient
  module CertificateStorage
    class S3
      def initialize
        @base_prefix = if ApartmentAcmeClient.lets_encrypt_test_server_enabled
                         TEST_PREFIX
                       else
                         ''
        end
      end

      ENCRYPTION_S3_NAME = 'server_encryption_client_private_key.der'
      CSR_ENCRYPTION_S3_NAME = 'csr_server_encryption_client_private_key.der'

      def store_certificate_string(certificate_string)
        File.write(cert_path('cert.pem'), certificate_string)
        store_s3_file(derived_filename('cert.pem'), certificate_string)
      end

      def store_csr_private_key_string(csr_private_key_string)
        File.write(cert_path('privkey.pem'), csr_private_key_string)
        store_s3_file(derived_filename('privkey.pem'), csr_private_key_string)
      end

      # do we have a certificate on this server?
      # We cannot start nginx when it is pointing at a non-existing certificate,
      # so we need to check
      def cert_exists?
        File.exist?(cert_path('privkey.pem'))
      end

      def private_key
        s3_object = s3_file(private_key_s3_filename)
        return nil unless s3_object.exists?

        s3_object.get.body.read
      end

      def csr_private_key
        s3_object = s3_file(csr_private_key_s3_filename)
        return nil unless s3_object.exists?

        s3_object.get.body.read
      end

      # saves a private key to s3
      def save_private_key(private_key)
        store_s3_file(private_key_s3_filename, private_key.to_der)
      end

      def save_csr_private_key(private_key)
        store_s3_file(csr_private_key_s3_filename, private_key.to_der)
      end


      private

      def private_key_s3_filename
        derived_filename(ENCRYPTION_S3_NAME)
      end

      def csr_private_key_s3_filename
        derived_filename(CSR_ENCRYPTION_S3_NAME)
      end

      def derived_filename(filename)
        "#{@base_prefix}#{filename}"
      end

      def store_s3_file(filename, file_contents)
        object = s3_file(filename)
        object.put(body: file_contents)
      end

      def cert_path(filename)
        File.join(ApartmentAcmeClient.certificate_storage_folder, derived_filename(filename))
      end

      def s3_file(filename)
        s3 = Aws::S3::Resource.new(region: ApartmentAcmeClient.aws_region)
        object = s3.bucket(ApartmentAcmeClient.aws_bucket).object(filename)
        object
      end
    end
  end
end
