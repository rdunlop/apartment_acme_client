require 'spec_helper'

RSpec.describe ApartmentAcmeClient::VerificationsController, :type => :controller do
  routes { ApartmentAcmeClient::Engine.routes }

  describe "#verify" do
    it "returns TRUE by default" do
      get :verify
      expect(response.body).to eq("TRUE")
    end
  end
end
