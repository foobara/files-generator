module Foobara
  class FilesGenerator
    module Types
      class GeneratedFile < Foobara::Model
        attributes do
          content :string, :required
          start_marker :string, :allow_nil
          end_marker :string, :allow_nil
        end
      end
    end
  end
end
