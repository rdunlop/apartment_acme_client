module ApartmentAcmeClient
  module FileManipulation
    class Proxy
      def self.singleton
        base_class.new
      end

      def self.base_class
        ApartmentAcmeClient.file_manipulation_class || FileManipulation::Real
      end
    end
  end
end
