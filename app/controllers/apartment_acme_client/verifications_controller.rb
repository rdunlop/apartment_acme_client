class ApartmentAcmeClient::VerificationsController < ApartmentAcmeClient::ApplicationController
  def verify
    render plain: "TRUE"
  end
end
