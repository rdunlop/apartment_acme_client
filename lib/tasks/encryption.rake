namespace :encryption do
  desc "Register a LetsEncrypt Client, create an open SSL key on S3 bucket"
  task :create_crypto_client, [:email] => :environment do |_t, args|
    ApartmentAcmeClient::Encryption.new.register_new(args[:email])
    puts "done."
  end

  desc "Authorize all domains and request new certificate"
  task renew_and_update_certificate: :environment do
    ApartmentAcmeClient::RenewalService.run!
  end

  desc "Update the nginx_configuration"
  task update_nginx_config: :environment do
    puts "updating nginx configuration"
    ssl_enabled = ApartmentAcmeClient::CertificateStorage::Proxy.singleton.cert_exists?
    base_domain = ApartmentAcmeClient.common_name
    ApartmentAcmeClient::NginxConfiguration::Proxy.base_class.update_nginx(cert_exists: ssl_enabled, base_domain: base_domain)
    puts "done."
  end
end
