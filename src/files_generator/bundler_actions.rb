require "bundler"

module Foobara
  class FilesGenerator
    module BundlerActions
      def bundle_install
        puts "bundling..."
        cmd = "bundle install"

        Bundler.with_unbundled_env do
          run_cmd_and_write_output(cmd, raise_if_fails: false)
        end
      end
    end
  end
end
