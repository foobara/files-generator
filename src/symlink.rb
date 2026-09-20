module Foobara
  class FilesGenerator
    class Symlink < String
      @mutex = Mutex.new

      class << self
        def supported?
          return @supported if defined?(@supported)
          # simplecov:disable-next
          return @supported if @mutex.nil?

          @mutex.synchronize do
            target_path = ".foobara-symlink-test-target"
            symlink_path = ".foobara-symlink-test-link"

            @supported = begin
              FileUtils.rm_f(target_path)
              FileUtils.rm_f(symlink_path)

              File.write(target_path, "hi!")
              File.symlink(target_path, symlink_path)

              File.symlink?(symlink_path)
            # TODO: figure out which of these actually happen in Windows
            # rubocop:disable-next Lint/ShadowedException
            rescue Errno::EACCES, NotImplementedError, SystemCallError
              # TODO: come up with a way to test this
              # simplecov:disable
              false
            # simplecov:enable
            ensure
              FileUtils.rm_f(target_path)
              FileUtils.rm_f(symlink_path)
            end

            @mutex = nil
            @supported
          end
        end
      end
    end
  end
end
