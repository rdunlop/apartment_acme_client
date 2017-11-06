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
  spec.homepage    = 'https://github.com/rdunlop/apartment_acme_client'
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # spec.files         = `git ls-files -z`.split("\x0").reject do |f|
  #   f.match(%r{^(test|spec|features)/})
  # end
  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 4.1.0", "< 5.2"

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "acme-client", "~> 0.3.1"
  spec.add_runtime_dependency "aws-sdk-s3", "~> 1"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "pry"
end
