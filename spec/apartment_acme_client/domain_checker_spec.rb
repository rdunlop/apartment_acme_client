require 'spec_helper'

RSpec.describe ApartmentAcmeClient::DomainChecker do
  it "can be instantiated" do
    expect(described_class.new).not_to be_nil
  end

  it "can check accessible_domains" do
    ApartmentAcmeClient.domains_to_check = ["a.com"]
    expect(described_class.new.accessible_domains).not_to be_nil
  end
end
