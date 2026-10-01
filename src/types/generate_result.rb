require_relative "generated_file"

module Foobara
  class FilesGenerator
    module Types
      GENERATE_RESULT = FilesGenerator.foobara_register_type(
        [:Types, :generate_result],
        :associative_array,
        key_type_declaration: :string,
        value_type_declaration: GeneratedFile
      )
    end
  end
end
