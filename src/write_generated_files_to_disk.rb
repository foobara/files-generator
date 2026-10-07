require "fileutils"
require "open3"
require_relative "../version"

module Foobara
  module Generators
    class WriteGeneratedFilesToDisk < Foobara::Command
      class CouldNotExecuteError < StandardError; end

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

      def empty_generated_files_json(version = FilesGenerator::VERSION)
        {
          files: [],
          metadata: {
            files_generator: version
          }
        }
      end

      def generate_generated_files_json
        generated_files_hash = empty_generated_files_json
        files = generated_files_hash[:files]

        paths_to_source_code.keys.sort.each do |file_path|
          generated_file = paths_to_source_code[file_path]
          file_info = { file_path: }

          start_marker = generated_file.start_marker
          file_info[:start_marker] = start_marker if start_marker

          end_marker = generated_file.end_marker
          file_info[:end_marker] = end_marker if end_marker

          files << file_info
        end

        content = JSON.generate(generated_files_hash)

        paths_to_source_code[generated_files_json_filename] = FilesGenerator::Types::GeneratedFile.new(content:)
      end

      def old_generated_files_json_contents
        file_list_file = "#{output_directory}/#{generated_files_json_filename}"

        return unless File.exist?(file_list_file)

        contents = JSON.parse(File.read(file_list_file))

        if contents.is_a?(::Array)
          file_paths = contents

          contents = empty_generated_files_json("0.1.5")
          files = contents[:files]

          file_paths.each do |file_path|
            files << FilesGenerator::Types::GeneratedFileRecord.new(file_path:)
          end
        else
          contents = Util.deep_symbolize_keys(contents)

          contents[:files].map! do |generated_file_data|
            FilesGenerator::Types::GeneratedFileRecord.new(**generated_file_data)
          end
        end

        contents
      end

      def old_generated_files_path(key = self.class.generator_key)
        "#{output_directory}/#{generated_files_json_filename(key)}"
      end

      def delete_old_files_if_needed
        rotate_old_generated_files_json_if_needed

        generated_files_info = old_generated_files_json_contents

        return unless generated_files_info

        generated_files_info[:files].map do |generated_file_record|
          Thread.new do
            file_path = File.join(output_directory, generated_file_record.file_path)

            if generated_file_record.start_marker
              remove_generated_section_from_file(generated_file_record, file_path)
            else
              FileUtils.rm_f file_path
            end
          end
        end.each(&:join)
      end

      def rotate_old_generated_files_json_if_needed
        keys = self.class.generator_key

        return unless keys.is_a?(::Array)

        key, *deprecated_keys = keys

        non_deprecated_path = old_generated_files_path(key)
        return if File.exist?(non_deprecated_path)

        deprecated_keys.each do |key|
          path = old_generated_files_path(key)

          if File.exist?(path)
            FileUtils.mv(path, non_deprecated_path)
            break
          end
        end
      end

      def write_all_files_to_disk
        paths_to_source_code.map do |path, generated_file|
          Thread.new do
            content = generated_file.content
            write_file_to_disk(path, content) # unless path == generated_files_json_filename
          end
        end.each(&:join)
      end

      def write_file_to_disk(path, contents)
        path = File.join(output_directory, path)
        FileUtils.mkdir_p(File.dirname(path))

        if contents.is_a?(FilesGenerator::Symlink)
          if FilesGenerator::Symlink.supported?
            # simplecov:disable
            unless File.symlink?(path)
              # simplecov:enable
              File.symlink(contents, path)
            end
            # simplecov:disable
          else
            # TODO: come up with a way to test this path
            FileUtils.cp_r(contents, path)
            # simplecov:enable
          end
        else
          File.write(path, contents)
        end
      end

      def generated_files_json_filename(key = self.class.generator_key)
        if key
          key = key.first if key.is_a?(::Array)

          "#{key}-generator.json"
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
            # simplecov:disable
            message = "Could not #{cmd}\n#{stderr.read}"
            if raise_if_fails
              raise CouldNotExecuteError, message
            else
              warn "WARNING: #{message}"
            end
            # simplecov:enable
          end

          exit_status
        end
      rescue Errno::ENOENT
        message = "Could not run: #{cmd}\nMaybe it is not installed?"

        if raise_if_fails
          raise CouldNotExecuteError, message
        else
          warn "WARNING: #{message}"
        end

        nil
      end

      def run_cmd_and_return_output(cmd)
        retval = +""

        Open3.popen3(cmd) do |_stdin, stdout, stderr, wait_thr|
          loop do
            line = stdout.gets
            break unless line

            retval << line
          end

          exit_status = wait_thr.value
          unless exit_status.success?
            # simplecov:disable
            raise CouldNotExecuteError, "could not #{cmd}\n#{stderr.read}"
          end
          # simplecov:enable
        end
      rescue Errno::ENOENT
        raise CouldNotExecuteError, "Could not run: #{cmd}\nMaybe it is not installed?"
      end

      def stats
        "Wrote #{paths_to_source_code.size} files to #{output_directory}"
      end

      def remove_generated_section_from_file(generated_file_record, file_path)
        # simplecov:disable
        return unless File.exist?(file_path)
        # simplecov:enable

        start_marker = generated_file_record.start_marker
        end_marker = generated_file_record.end_marker

        contents = File.read(file_path)

        start_index = contents.index(start_marker)

        # simplecov:disable
        return unless start_index
        # simplecov:enable

        end_index = contents[(start_index + start_marker.size)..].index(end_marker)

        # simplecov:disable
        return unless end_index
        # simplecov:enable

        end_index += start_index + start_marker.size
        end_index += end_marker.size

        keep_first = contents[0...start_index]
        keep_last = contents[end_index..]

        contents = keep_first + keep_last

        if contents.strip.empty?
          FileUtils.rm_f(file_path)
        else
          File.write(file_path, contents)
        end
      end
    end
  end
end
