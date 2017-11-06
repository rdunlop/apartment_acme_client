module Stubs
  class FakeCertificateStorage
    def store_certificate(certificate)
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
