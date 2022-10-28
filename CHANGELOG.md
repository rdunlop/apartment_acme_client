# Future features

# 0.0.8

* Expand Rails compatibility to include rails 7.x

# 0.0.7

* Add CircleCI Config
* Fix Rubocop warnings (now enforced by CI)
* Expand Rails compatibility to include rails 6.x

# 0.0.6

* Add small delay between DNS update and LetsEncrypt authorization request
* Add some more detailed logging during renewal sequence

# 0.0.5

* Fix ACMEv2 client integration with http validation

# 0.0.4 [broken]

* Use ACMEv2 client
* Enable provisioning Wildcard certificate
* Use AWS Route53 API for creating wildcard certificate

# 0.0.3

* Allow Rails 5.2.x

# 0.0.2

* Allow Rails 5.2
* Updated Acme Client dependency
* Ability to trigger the re-generation of certificates at will (not only on a schedule)
* Make the renew_certs more modular, allowing users to specify a ERB template
* Create an installation task which creates an initializer file, if one doesn't exist?

# 0.0.1

* Initial extraction of this engine from the main application
* No new features
* Improved Test coverage
