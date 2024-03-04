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

      result :associative_array

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
        write_file_to_disk(generated_files_json_filename, paths_to_source_code[generated_files_json_filename])

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
    end
  end
end
