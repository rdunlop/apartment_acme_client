module Stubs
  class FakeAcmeClient
    def initialize(options = {})
    end

    def register(email)
    end

    def request_certificate(options = {})
      true
    end

    def authorize(domain:)
      OpenStruct.new(http01: challenge)
    end

    private

    def challenge
      OpenStruct.new(
        token: "something",
        filename: "afile",
        file_content: "some content",
        verify_status: "valid",
      )
    end
  end
end
