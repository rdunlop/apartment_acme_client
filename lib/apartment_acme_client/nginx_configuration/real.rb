require "erb"

module ApartmentAcmeClient
  module NginxConfiguration
    class Real
      # do we have a certificate on this server?
      # We cannot start nginx when it is pointing at a non-existing certificate,
      # so we need to check
      def self.update_nginx(cert_exists:, base_domain:)
        template = new(include_ssl: cert_exists, base_domain: base_domain).filled_template

        tempfile = Tempfile.new('nginx_config')
        raise "Path Error" unless template

        begin
          tempfile.write(template)
          tempfile.flush

          ApartmentAcmeClient::FileManipulation::Proxy.singleton.copy_file(tempfile.path.to_s, ApartmentAcmeClient.nginx_config_path)
          ApartmentAcmeClient::FileManipulation::Proxy.singleton.restart_service("nginx")
        ensure
          tempfile.close
          tempfile.unlink
        end
      end

      def initialize(options = {})
        @options = default_options.merge(options)
      end

      def filled_template
        return nil unless check_configuration

        fill_template(read_template, @options)
      end

      def default_options
        result = {}
        result[:public_folder] = ApartmentAcmeClient.public_folder
        result[:socket_path] = ApartmentAcmeClient.socket_path
        result[:include_ssl] = false
        result[:cert_prefix] = ApartmentAcmeClient::CertificateStorage::TEST_PREFIX if ApartmentAcmeClient.lets_encrypt_test_server_enabled
        result[:certificate_storage_folder] = ApartmentAcmeClient.certificate_storage_folder
        result
      end

      def check_configuration
        unless File.exist?(@options[:public_folder])
          puts "Webroot path #{@options[:public_folder]} Not found"
          return false
        end

        true
      end

      def read_template
        default_template
      end

      def default_template
        <<~THE_END
          #
          # A virtual host using mix of IP-, name-, and port-based configuration
          #

          upstream app {
              # Path to Unicorn SOCK file, as defined previously
              server unix:<%= options[:socket_path] %> fail_timeout=0;
          }

          server {

              # FOR HTTP
              listen 80;

              gzip on;

              # Application root, as defined previously
              root <%= options[:public_folder] %>;
              server_name  <%= options[:base_domain] %> *.<%= options[:base_domain] %>;

              try_files $uri/index.html $uri @app;

              location @app {
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-FORWARDED-PROTO $scheme;
                  proxy_set_header Host $http_host;
                  proxy_redirect off;
                  proxy_pass http://app;
              }

              error_page 500 502 503 504 /500.html;
              client_max_body_size 4G;
              keepalive_timeout 10;

              # BELOW THIS LINE FOR HTTPS
              <% if options[:include_ssl] %>
              listen 443 default_server ssl;

              # The following should be enabled once everything is SSL
              # ssl on;

              ssl_certificate <%= options[:certificate_storage_folder] %>/<%= options[:cert_prefix] %>cert.pem;
              ssl_certificate_key <%= options[:certificate_storage_folder] %>/<%= options[:cert_prefix] %>privkey.pem;

              ssl_stapling on;
              ssl_stapling_verify on;

              ssl_session_timeout 5m;
              <% end %>
          }
        THE_END
      end

      def fill_template(template, options)
        # scope defined for use in binding to ERB
        def opts(options)
          options
          binding
        end
        # binds to current class
        # uses 'options' in the template
        ERB.new(template).result(opts(options))
      end
    end
  end
end
