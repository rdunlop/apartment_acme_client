# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "apartment_acme_client/version"

Gem::Specification.new do |spec|
  spec.name          = "apartment_acme_client"
  spec.version       = ApartmentAcmeClient::VERSION
  spec.authors       = ["Robin Dunlop"]
  spec.email         = ["robin@dunlopweb.com"]

  spec.summary          = %q{Let's Encrypt interface for Multi-tenancy applications (like Apartment)}
  spec.description      = %q{Manage/renew Let's Encrypt SSL Certificates for sites which respond to many different domains}
  spec.homepage = 'https://github.com/rdunlop/apartment_acme_client'
  spec.license = "MIT"

  # spec.files         = `git ls-files -z`.split("\x0").reject do |f|
  #   f.match(%r{^(test|spec|features)/})
  # end
  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 4.1.0", "< 8"

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'acme-client', '~> 2.0.0'
  spec.add_runtime_dependency "aws-sdk-route53", "~> 1"
  spec.add_runtime_dependency "aws-sdk-s3", "~> 1"
  spec.add_development_dependency "bundler", "> 2.1.4"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency "sqlite3"
end
