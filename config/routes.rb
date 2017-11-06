ApartmentAcmeClient::Engine.routes.draw do
  get '/verify', to: "verifications#verify"
end
