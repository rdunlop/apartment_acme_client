# frozen_string_literal: true

module ApartmentAcmeClient
  class RenewalService
    def self.run!
      good_domains, rejected_domains = ApartmentAcmeClient::DomainChecker.new.accessible_domains
      puts "All domains to be requested: #{good_domains}, invalid domains: #{rejected_domains}"

      common_name = ApartmentAcmeClient.common_name || good_domains.first

      encryptor = ApartmentAcmeClient::Encryption.new
      certificate = encryptor.request_certificate(common_name: common_name, domains: good_domains, wildcard_domain: ApartmentAcmeClient.wildcard_domain)

      ApartmentAcmeClient::CertificateStorage::Proxy.singleton.store_certificate_string(certificate)
      ApartmentAcmeClient::CertificateStorage::Proxy.singleton.store_csr_private_key_string(encryptor.csr_private_key_string)

      puts 'Restarting nginx with new certificate'
      ApartmentAcmeClient::FileManipulation::Proxy.singleton.restart_service('nginx')

      puts 'done.'
    end
  end
end
