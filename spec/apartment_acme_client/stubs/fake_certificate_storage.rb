module Stubs
  class FakeCertificateStorage
    def store_certificate_string(certificate)
    end

    def store_csr_private_key_string(private_key)
    end

    def cert_exists?
    end

    def private_key
    end

    def save_private_key(private_key)
      true
    end
  end
end
