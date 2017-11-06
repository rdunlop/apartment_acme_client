require "apartment_acme_client/version"
require "apartment_acme_client/domain_checker"
require "apartment_acme_client/encryption"
require "apartment_acme_client/renewal_service"
require "apartment_acme_client/engine"
require "apartment_acme_client/acme_client/proxy"
require "apartment_acme_client/acme_client/real_client"
require "apartment_acme_client/certificate_storage/proxy"
require "apartment_acme_client/certificate_storage/s3"
require "apartment_acme_client/nginx_configuration/proxy"
require "apartment_acme_client/nginx_configuration/real"
require "apartment_acme_client/file_manipulation/proxy"
require "apartment_acme_client/file_manipulation/real"

require 'apartment_acme_client/railtie' if defined?(Rails)

module ApartmentAcmeClient
  # A callback method which lists the possible domains to be checked
  # We will verify each of them before requesting a certificate from Let's Encrypt for all of them
  mattr_accessor :domains_to_check

  def self.domains_to_check
    if @@domains_to_check.respond_to?(:call)
      @@domains_to_check.call
    else
      @@domains_to_check
    end
  end

  # The base domain, a domain which is always going to be accessible.
  # because we need a common domain to be used on each request.
  # if not defined, the first 'domain_to_check' which succeeds will be used
  mattr_accessor :common_name

  # Directory where to store the challenge files, Must be accessible via the internet
  mattr_accessor :public_folder # Rails.root.join('public')

  # Directory where to store certificates locally
  # must persist between deployments, so that nginx can reference it permanently
  mattr_accessor :certificate_storage_folder # Rails.root.join("public", "system")

  # for s3 storage
  mattr_accessor :aws_region # Rails.application.secrets.aws_region
  mattr_accessor :aws_bucket # Rails.application.secrets.aws_bucket

  # For use in the nginx configuration
  mattr_accessor :socket_path # = "/tmp/unicorn-application.socket"
  mattr_accessor :nginx_config_path # "/etc/nginx/conf.d/site.conf"

  # If your server stops responding 200 OK to http connections (ie: when all connections are forced-ssl)
  # you must verify new subdomains over https instead of http
  mattr_accessor :verify_over_https

  # For Testing/injection purposes
  mattr_accessor :acme_client_class
  mattr_accessor :certificate_storage_class
  mattr_accessor :file_manipulation_class
  mattr_accessor :nginx_configuration_class

  mattr_accessor :lets_encrypt_test_server_enabled
end
