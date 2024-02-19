module Foobara
  module Generators
    class WriteGeneratedFilesToDisk < Foobara::Command
      inputs do
        output_directory :string, :required
      end

      result :associative_array

      attr_accessor :paths_to_source_code

      def delete_old_files_if_needed
        file_list_file = "#{output_directory}/foobara-generated.json"

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
        write_file_to_disk("foobara-generated.json", paths_to_source_code["foobara-generated.json"])

        paths_to_source_code.map do |path, contents|
          Thread.new { write_file_to_disk(path, contents) unless path == "foobara-generated.json" }
        end.each(&:join)
      end

      def write_file_to_disk(path, contents)
        path = "#{output_directory}/#{path}"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, contents)
      end
    end
  end
end
