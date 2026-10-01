require "foobara/all"

module Foobara
  class FilesGenerator
    foobara_domain!
  end
end

Foobara::Util.require_directory "#{__dir__}/../../src"
