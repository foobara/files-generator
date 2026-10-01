module Foobara
  class FilesGenerator
    module Types
      class GeneratedFileRecord < Foobara::Model
        attributes do
          file_path :string, :required
          start_marker :string, :allow_nil
          end_marker :string, :allow_nil
        end
      end
    end
  end
end
