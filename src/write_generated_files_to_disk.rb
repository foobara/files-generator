require "open3"

module Foobara
  module Generators
    class WriteGeneratedFilesToDisk < Foobara::Command
      class << self
        def generator_key
          nil
        end
      end

      inputs do
        output_directory :string, :required
      end

      result :string

      attr_accessor :paths_to_source_code

      def generate_generated_files_json
        paths_to_source_code[generated_files_json_filename] = "[\n#{
          paths_to_source_code.keys.sort.map { |k| "  \"#{k}\"" }.join(",\n")
        }\n]\n"
      end

      def delete_old_files_if_needed
        file_list_file = "#{output_directory}/#{generated_files_json_filename}"

        if File.exist?(file_list_file)
          # :nocov:
          file_list = JSON.parse(File.read(file_list_file))

          file_list.map do |file|
            Thread.new { FileUtils.rm("#{output_directory}/#{file}") }
          end.each(&:join)
          # :nocov:
        end
      end

      def write_all_files_to_disk
        if paths_to_source_code.key?(generated_files_json_filename)
          write_file_to_disk(generated_files_json_filename, paths_to_source_code[generated_files_json_filename])
        end

        paths_to_source_code.map do |path, contents|
          Thread.new { write_file_to_disk(path, contents) unless path == generated_files_json_filename }
        end.each(&:join)
      end

      def write_file_to_disk(path, contents)
        path = "#{output_directory}/#{path}"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, contents)
      end

      def generated_files_json_filename
        key = self.class.generator_key

        if key
          # TODO: test this path
          # :nocov:
          "#{key}-generator.json"
          # :nocov:
        else
          "foobara-generated.json"
        end
      end

      # TODO: probably needs a better name
      def run_cmd_and_write_output(cmd, raise_if_fails: true)
        Open3.popen3(cmd) do |_stdin, stdout, stderr, wait_thr|
          loop do
            line = stdout.gets
            break unless line

            puts line
          end

          exit_status = wait_thr.value
          unless exit_status.success?
            # :nocov:
            if raise_if_fails
              raise "could not #{cmd}\n#{stderr.read}"
            else
              warn "WARNING: could not #{cmd}\n#{stderr.read}"
            end
            # :nocov:
          end
        end
      rescue Errno::ENOENT
        if raise_if_fails
          raise
        else
          warn "WARNING: could not run: #{cmd}\nMaybe it is not installed?"
        end
      end

      def run_cmd_and_return_output(cmd)
        retval = ""

        Open3.popen3(cmd) do |_stdin, stdout, stderr, wait_thr|
          loop do
            line = stdout.gets
            break unless line

            retval << line
          end

          exit_status = wait_thr.value
          unless exit_status.success?
            # :nocov:
            raise "could not #{cmd}\n#{stderr.read}"
          end
          # :nocov:
        end

        retval
      end

      def stats
        "Wrote #{paths_to_source_code.size} files to #{output_directory}"
      end
    end
  end
end
