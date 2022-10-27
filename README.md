# ApartmentAcmeClient

Let's Encrypt interface for Multi-tenancy applications which respond by on many domains/subdomains (like Apartment)

If you have a single server which responds to many different domains, getting Let's Encrypt to provide you with a multi-domain Certificate is possible, but a lot of work.


**Note**: This only works up to 100 domains (https://letsencrypt.org/docs/rate-limits/)
Reference: https://community.letsencrypt.org/t/host-multiple-domains-with-a-single-certificate/20917/2

**Note**: Example usage with real server. Apartment gem with subdomains.
Reference: https://github.com/influitive/apartment#switch-on-subdomain

The goal of this gem is to solve the following problems:

1) Make it easy to start using let's encrypt for multiple domains on one server
1) Make it easy to periodically refresh a certificate which handles many domains
1) Make it possible to add a new custom DNS entry which refers to the server, and request a cert which now also covers that new domain.
1) Make it easy to request a wildcard cert as well as individual domain certs
1) Make it resilient, if a DNS record is removed, handle that by removing that domain from list requested for the cert.

**Example Situation**:

- Your application is known as site.example.com
- You allow users to create new accounts, and assign each account a separate subdomain,
  - e.g. alice.site.example.com, bob.site.example.com, charlie.site.example.com
- You allow users to also whitelabel the service by buying their own domains, and setting up CNAME records:
  - e.g. www.alice.com -> CNAME: alice.site.example.com
  - e.g. bobrocks.com -> CNAME: bob.site.example.com

**What can ApartmentAcmeClient do?**

- Create a single Let's Encrypt SSL Certificate which covers all of:
  - site.example.com
  - *.site.example.com (which covers alice.site.example.com, bob.site.example.com, charlie.site.example.com)
  - www.alice.com
  - bobrocks.com

SSL Certificates
----------------

In order to provide a secure connection, we are using [letsencrypt.org](https://letsencrypt.org) to
automatically create ssl certificates for the various domains which the server will run on. But, we are doing the validation/registration through the `acme-client` gem instead of using the lets-encrypt binary.

Periodically, we check all configured domains, and re-configure the nginx server to properly respond to any newly configured domain names. If we have a new domain name, we also request a new SSL certificate, enabling HTTPS for that domain.

How the Encryption process works:
---------------------------------

1. A list of domains which are served by this server is created.
2. The list of all these domains is used to determine which ones are properly configured in DNS.
3. We `authorize` each domain with LetsEncrypt
4. A new SSL certificate is requested and installed3
5. Nginx is restarted to pick up the new certificate.

Setting up crypto the first time:
---------------------------------

1. `rake encryption:create_crypto_client` - Register an account with LetsEncrypt
2. `rake encryption:renew_and_update_certificate` - Authorize/create certificates
3. `rake encryption:update_nginx_config` - re-write the nginx file to point at the certificates

At this point, the only thing necessary is to run `rake encryption:renew_and_update_certificate` on a regular basis, which will find new domains, authorize them, and get new SSL certs for them.

See below for a detailed explanation of "First Time Setup"

## Testing things out

When setting this up the first time, it is recommended that you enable test-mode:
```ruby
# in config/initializers/apartment_acme_client.rb

ApartmentAcmeClient.lets_encrypt_test_server_enabled = true
```

so that all your requests are made against the test Let's Encrypt server.

This will also cause your DER and PEM files to be prefixed with "test_" to make it possible to have REAL and FAKE certs in parallel

Once you have an SSL Cert installed which is doing everything correctly (except not from the "REAL" server) you can restart the process.
- Set `ApartmentAcmeClient.lets_encrypt_test_server_enabled = false`

start at step 1 (`rake encryption:create_crypto_client`)....

-----------------------------------
## Pre-requisites

In order for the application to function properly, it is assumed that the application is running in the following configuration:

- Nginx running as a service with a socket tunnel to the rails application
- Nginx can be restarted by `sudo service nginx restart`
- Rails application running, which can serve files from a `/public`-like directory

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apartment_acme_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apartment_acme_client

## Usage

### Mount the engine

We do this so that we can verify the site responds to a URL before we ask Lets Encrypt to verify the site.

```ruby
mount ApartmentAcmeClient::Engine => '/aac' # you can define whatever path you want to mount the engine
```

### Configure the client

Create an initializer for the client. Usually `config/initializers/apartment_acme_client.rb`

Add the following configuration entries

#### Specify the domains to be checked

Define the code which will list the domains to check.

```ruby
# Should return an array of domains (without http/https prefixes)

# It can be a straight array, or a callable object
# These should be all of the domains which are NOT
# covered by the wildcard settings
ApartmentAcmeClient.domains_to_check = -> { SomeModel.all.map(&:custom_domain) }
ApartmentAcmeClient.wildcard_domain = "site.example.com" # optional element

# e.g.
# ApartmentAcmeClient.domains_to_check = ["example.com", "alice.example.com", "alice.com"]
```

#### Wildcard domain

You can request a wildcard certificate for a domain (or a subdomain). In order to do this, the system must be able to write to the DNS provider.

Currently, only Route53 is supported as a DNS provider, and we use an `upsert` to write a TXT record to the system, in order to prove that we control the DNS for the domain.

If you specify `wildcard_domain` (the domain on which to request a wildcard cert), we will request a wilcard cert for `*.<wildcard_domain>`, and use AWS Route53 API to perform the domain-authorization.

The necessary permissions to be able to update the Route53 records for wildcard-cert update are:
- route53:ListHostedZones
- route53:ChangeResourceRecordSets

#### Specify the common-name domain

This is used to identify the certificate requested, and should be the same from week-to-week.

This should be a URL which you control the DNS for, ensuring that it will ALWAYS be pointing at your application. (ie: not subject to the whims of your users).

Note: The nginx configuration will be configured to respond to `common_name` and `*.common_name` sources.

```ruby
ApartmentAcmeClient.common_name = "example.com"
```

#### Specify public folder

Specify where to put the "challenge" files which can be fetched by let's encrypt when validating the domains

**Note**: this folder should be not be derived from Rails.root, because that is a sym-link, which changes release to release.

```ruby
ApartmentAcmeClient.public_folder = "/home/ec2-user/app/current/public" # not: Rails.root.join('public')
```

#### Where to store the certificates on the server

Directory where to store certificates locally. This folder must persist between deployments, so that nginx can reference it permanently.
```ruby
ApartmentAcmeClient.certificate_storage_folder = "/home/ec2-user/app/current/public/system" # not: Rails.root.join("public", "system")
```

If you are using capistrano for deployments, add public/system to your `linked_dirs`

```ruby
# deploy.rb
set :linked_dirs, %w[public/system]
```

#### S3 Backup Storage settings

Each time a certificate is requested from Let's Encrypt, we also store it in S3 in case something happens to the server/filesystem.

In order for this to work, you must specify the aws_region and aws_bucket

```ruby
ApartmentAcmeClient.aws_region = Rails.application.secrets.aws_region
ApartmentAcmeClient.aws_bucket = Rails.application.secrets.aws_bucket
```

#### Nginx configuration settings

It is assumed that the /etc/nginx/nginx.conf file has a line like:
```
http {
    # Many lines....

    include /etc/nginx/conf.d/*.conf;
}
```

Then, the site's configuration is actually stored in /etc/nginx/conf.d/site.conf

So, the nginx_config_path would be
```ruby
ApartmentAcmeClient.nginx_config_path = "/etc/nginx/conf.d/site.conf"
```

Assuming that your application is running unicorn with a socket.

Example:
```
# workers
worker_processes 1

# listen
listen "/tmp/unicorn-application.socket", backlog: 64

# Many more lines....
```

```ruby
ApartmentAcmeClient.socket_path = "/tmp/unicorn-application.socket"
```

#### Force-SSL Options

If you ever choose to enable force-ssl on your server, you will need to set
the `ApartmentAcmeClient.verify_over_https = true` so that verification checks occur
over https instead of http

------------------------------------------------------
## First Time Setup

1) Register with Let's Encrypt

Before we can make requests to Let's encrypt, we need to create a private key, which we will use for all future requests to Let's encrypt. To do this, run `rake encryption:create_crypto_client[my_email@example.com]` (replacing the email address with yours)

This will create a new private key, store it on S3, and register that key with let's encrypt for your e-mail address.

2) Create your initial certificate

Initially, your nginx configuration will not reference any ssl certificate files, because you don't have any.
So the first thing you must do is request an initial certificate using `rake encryption:renew_and_update_certificate`

Once this is done, the newly acquired certificate will be stored on the server, for use by nginx in step 3.

3) Tell Nginx where to get it's SSL certificates

The Nginx configuration must be updated to point to the SSL Certificate location.

run `rake encryption:update_nginx_config` in order to write the ngnix configuration file, and restart the nginx service.

At this point, the only thing necessary is to run `rake encryption:renew_and_update_certificate` on a regular basis, which will find new domains, authorize them, and get new SSL certs for them. It will also restart nginx, to have it pick up the new certificate.

------------------------------------------------------
### Schedule a weekly task to be run.

Each week, the certificates should be renewed. We have provided 2 ways to do this.

straight invocation:
```ruby
  ApartmentAcmeClient::RenewalService.run!
```

we provide a helper rake task:
```ruby
rake "encryption:renew_and_update_certificate"
```

Please use whatever scheduling service you wish in order to ensure that this runs periodically.
e.g. [whenever](https://github.com/javan/whenever)

----------------------------------------------------------------------
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rdunlop/apartment_acme_client.

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).

--------------------------------------------

## Known issues

- Depends on the `aws-sdk-s3` S3 gem version "~> 1".
- It expects the hosting application has configured the AWS credentials.

e.g.:
```ruby
Aws.config.update(
  region: Rails.application.secrets.aws_region,
  credentials: Aws::Credentials.new(
    Rails.application.secrets.aws_access_key,
    Rails.application.secrets.aws_secret_access_key
  )
)
```
