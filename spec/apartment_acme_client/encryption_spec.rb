require 'spec_helper'

RSpec.describe ApartmentAcmeClient::Encryption do
  before { ApartmentAcmeClient.public_folder = Rails.root.join("public") }
  before { ApartmentAcmeClient.acme_client_class = Stubs::FakeAcmeClient }
  before { ApartmentAcmeClient.certificate_storage_class = Stubs::FakeCertificateStorage }

  it "can be instantiated" do
    expect(described_class.new).not_to be_nil
  end

  it "can call request_certificate" do
    expect(described_class.new.request_certificate(common_name: "example.com", domains: ["a.com"])).not_to be_nil
  end

  it "can call authorize_domains" do
    expect(described_class.new.authorize_domains(["a.com"])).not_to be_nil
  end

  it "can call register_new" do
    expect(described_class.new.register_new("sam@example.com")).not_to be_nil
  end

end
