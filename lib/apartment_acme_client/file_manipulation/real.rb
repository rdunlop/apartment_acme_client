require "open3"

module ApartmentAcmeClient
  module FileManipulation
    class Real
      def copy_file(from, to)
        run_command("sudo cp #{from} #{to}")
      end

      def restart_service(service)
        run_command("sudo service #{service} restart")
      end

      private

      def run_command(command)
        Open3.popen3(command) do |_stdin, stdout, stderr, wait_thr|
          stdout_lines = stdout.read
          # puts "stdout is:" + stdout_lines

          # to watch the output as it runs:
          # while line = stdout.gets
          #   puts line
          # end

          stderr_lines = stderr.read
          # puts "stderr is:" + stderr_lines
          exit_status = wait_thr.value

          unless exit_status.success?
            abort "FAILED !!! #{command}"
          end
        end
      end
    end
  end
end
