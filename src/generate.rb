require "find"

module Foobara
  module Generators
    class Generate < Foobara::Command
      # TODO: specify a better type?
      result :associative_array

      attr_accessor :element_to_generate

      def base_generator
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def elements_to_generate
        @elements_to_generate ||= Set.new
      end

      def generated
        @generated ||= Set.new
      end

      def generated_elements
        @generated_elements ||= Set.new
      end

      def each_element_to_generate
        until elements_to_generate.empty?
          element_to_generate = elements_to_generate.first
          elements_to_generate.delete(element_to_generate)

          generators = if element_to_generate.is_a?(FilesGenerator)
                         if generated.include?(element_to_generate)
                           []
                         else
                           elements_to_generate << element_to_generate.relevant_manifest
                           [element_to_generate]
                         end
                       else
                         if generated_elements.include?(element_to_generate)
                           next
                         end

                         generated_elements << element_to_generate

                         base_generator.generators_for(element_to_generate).select do |generator|
                           generator.applicable? && !generated.include?(generator)
                         end
                       end

          generators.each do |generator|
            # TODO: change this name
            self.element_to_generate = generator
            generated << generator
            yield
          end
        end
      end

      def generate_element
        return unless element_to_generate.applicable?

        paths_to_source_code[Util.array(element_to_generate.target_path).join("/")] =
          element_to_generate.generate(elements_to_generate)
      end

      def include_non_templated_files
        templates_dir_pathname = Pathname.new(templates_dir)

        Find.find(templates_dir) do |file_path|
          next if File.directory?(file_path)
          next if file_path.end_with?(".erb")

          file_path = Pathname.new(file_path)

          relative_path = file_path.relative_path_from(templates_dir_pathname)

          paths_to_source_code[relative_path.to_s] = File.read(file_path)
        end
      end

      def templates_dir
        base_generator.templates_dir
      end

      def paths_to_source_code
        @paths_to_source_code ||= {}
      end
    end
  end
end
