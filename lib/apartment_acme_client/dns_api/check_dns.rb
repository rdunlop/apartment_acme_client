module ApartmentAcmeClient
  module DnsApi
    # Check to see if a particular DNS record is
    # present.
    class CheckDns
      attr_reader :root_domain, :dns_record

      def initialize(root_domain, dns_record)
        # ensure we only have the TLD, not a subdomain
        @root_domain = root_domain.split(".").last(2).join(".")
        @dns_record = dns_record
      end

      # Search DNS recodrs for any entries which are TXT and include
      # the text 'value'
      def check_dns(value)
        valid = true

        nameservers.each do |nameserver|
          begin
            records = Resolv::DNS.open(nameserver: nameserver) do |dns|
              dns.getresources(
                dns_record,
                Resolv::DNS::Resource::IN::TXT
              )
            end
            records = records.map(&:strings).flatten
            valid = records.include?(value)
          rescue Resolv::ResolvError
            return false
          end
          return false unless valid
        end

        valid
      end

      def nameservers
        return @nameservers if defined?(@nameservers)

        @nameservers = []
        Resolv::DNS.open(nameserver: '8.8.8.8') do |dns|
          while nameservers.empty?
            @nameservers = dns.getresources(
              root_domain,
              Resolv::DNS::Resource::IN::NS
            ).map(&:name).map(&:to_s)
          end
        end

        @nameservers
      end

      def wait_for_present(value, timeout_seconds: 120)
        time = 1
        until check_dns(value)
          puts "Waiting for DNS to update"
          sleep 1
          time += 1
          break if time > timeout_seconds
        end
      end
    end
  end
end
