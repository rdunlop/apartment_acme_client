require 'spec_helper'

RSpec.describe ApartmentAcmeClient::NginxConfiguration::Real do # rubocop:disable Metrics/BlockLength
  let(:root_path) { Rails.root.join("public") }
  before { ApartmentAcmeClient.certificate_storage_folder = root_path }
  before { ApartmentAcmeClient.public_folder = Rails.root.join("public") }
  before { ApartmentAcmeClient.file_manipulation_class = Stubs::FakeFileManipulation }

  context "update_nginx" do
    it "can write a new file" do
      described_class.update_nginx(cert_exists: false, base_domain: "example.com")
    end
  end

  it "can be instantiated" do
    expect(described_class.new).not_to be_nil
  end

  it "has a default template" do
    expect(described_class.new.default_template).to include("root")
  end

  it "fills in the template" do
    result = described_class.new.fill_template("<%= options[:hi] %>", hi: "Hello")
    expect(result).to eq("Hello")
  end

  it "fills the template with default options" do
    result = described_class.new.filled_template
    expect(result).to include("root #{root_path}")
  end

  context "when in test acme mode" do
    before { ApartmentAcmeClient.lets_encrypt_test_server_enabled = true }

    it "prefixes the certificates with test_" do
      result = described_class.new(include_ssl: true).filled_template
      expect(result).to include("ssl_certificate_key #{root_path}/test_privkey.pem;")
    end
  end
end
