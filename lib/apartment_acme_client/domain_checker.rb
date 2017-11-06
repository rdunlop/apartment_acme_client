module ApartmentAcmeClient
  class DomainChecker
    # returns an array containing 2 lists:
    # successful domains
    # rejected domains (those which don't appear properly configured in DNS)
    def accessible_domains
      possible_domains = ApartmentAcmeClient.domains_to_check

      domains = []
      rejected_domains = []
      possible_domains.each do |domain|
        if ApartmentAcmeClient::Verifier.new(domain).properly_configured?
          domains << domain
        else
          rejected_domains << domain
        end
      end
      [domains, rejected_domains]
    end
  end
end
