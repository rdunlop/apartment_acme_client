Rails.application.routes.draw do
  mount ApartmentAcmeClient::Engine => "/apartment_acme_client"
end
