require 'net/http'

module ApartmentAcmeClient
  class Verifier
    attr_reader :url

    def initialize(url)
      @url = url
      @verify_over_https = ApartmentAcmeClient.verify_over_https ? true : false
    end

    # Determine whether this alias is properly configured
    # Causes makes a request to a remote server (which should be THIS server)
    # and determines whether the request was properly received
    def properly_configured?
      options = {
        open_timeout: 5,
        use_ssl: @verify_over_https,
        verify_mode: OpenSSL::SSL::VERIFY_NONE # because we might not have a valid cert yet
      }
      Net::HTTP.start(url, options) do |http|
        # Because the engine could be mounted anywhere, we need to get the target
        # path from the Engine Routes
        verify_path = ApartmentAcmeClient::Engine.routes.url_helpers.verify_path
        response = http.get(verify_path)

        return false unless response.is_a?(Net::HTTPSuccess)

        response.body == "TRUE"
      end
    rescue SocketError, Net::OpenTimeout, Errno::ECONNREFUSED
      # SocketError if the server name doesn't exist in DNS
      # OpenTimeout if no server responds
      # ECONNREFUSED if the server responds with "No"
      false
    end
  end
end
