require 'spec_helper'

RSpec.describe ApartmentAcmeClient::RenewalService do
  before { ApartmentAcmeClient.acme_client_class = Stubs::FakeAcmeClient }
  before { ApartmentAcmeClient.certificate_storage_class = Stubs::FakeCertificateStorage }
  before { ApartmentAcmeClient.file_manipulation_class = Stubs::FakeFileManipulation }

  it "can be instantiated" do
    expect(described_class.new).not_to be_nil
  end

  describe "run!" do
    before do
      ApartmentAcmeClient.domains_to_check = ["a"]
    end

    it "can run" do
      described_class.run!
    end
  end
end
