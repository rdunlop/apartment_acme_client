require 'aws-sdk-route53'

module ApartmentAcmeClient
  module DnsApi
    # based on https://www.petekeen.net/lets-encrypt-without-certbot
    class Route53
      # The domain being requested for DNS update
      # e.g. "site.example.com"
      attr_reader :requested_domain

      # the DNS TXT record label (full label, including domain)
      attr_reader :label

      # will be TXT
      attr_reader :record_type

      # array of value keys to be written
      # (for wildcard certs, you'll have one for *.example.com, and one for example.com)
      # e.g. ["One", "Two"]
      attr_reader :values

      def initialize(requested_domain:, dns_record_label:, record_type:, values:)
        @requested_domain = requested_domain
        @label = dns_record_label
        @record_type = record_type
        @values = values
      end

      # NOTE: If you get error like:
      #
      # "Invalid Resource Record: FATAL problem:
      # InvalidCharacterString
      # (Value should be enclosed in quotation marks) encountered with <value>"
      #
      # this means that the "Value" should include escape quotes.
      # e.g. values: ["\"Something\"", "\"Other Thing\""]
      def write_record
        route53.change_resource_record_sets(options)
      end

      private

      def options
        change = {
          action: 'UPSERT',
          resource_record_set: {
            name: label,
            type: record_type,
            ttl: 1,
            resource_records: resource_record_values
          }
        }

        {
          hosted_zone_id: zone.id,
          change_batch: {
            changes: [change]
          }
        }
      end

      def root_domain
        requested_domain.split(".").last(2).join(".")
      end

      def zone
        @zone = route53.list_hosted_zones(max_items: 100)
                       .hosted_zones
                       .detect { |z| z.name = "#{root_domain}." }
      end

      def route53
        # NOTE: The `region` doesn't matter, because Route53 is global.
        @route53 ||= Aws::Route53::Client.new(region: 'us-east-1')
      end

      # createt an AwsRoute53 upsert with multiple value entries
      def resource_record_values
        values.map do |value|
          if value.include?("\"")
            { value: value }
          else
            { value: "\"#{value}\"" }
          end
        end
      end
    end
  end
end
