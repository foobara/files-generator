module Foobara
  class FilesGenerator
    include TruncatedInspect

    class << self
      def manifest_to_generator_classes(_manifest)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def generators_for(manifest)
        if manifest.is_a?(FilesGenerator)
          return [manifest]
        end

        generator_classes = manifest_to_generator_classes(manifest)

        Util.array(generator_classes).map do |generator_class|
          generator_class.new(manifest)
        end
      end

      def generator_for(manifest)
        generators_for(manifest).first
      end
    end

    attr_accessor :relevant_manifest, :belongs_to_dependency_group

    def initialize(relevant_manifest)
      self.relevant_manifest = relevant_manifest
    end

    def target_path
      *path, file = template_path

      if file.end_with?(".erb")
        [*path, file[0..-5]]
      else
        raise "expected a .erb extension. Maybe override #target_path"
      end
    end

    def target_dir
      target_path[0..-2]
    end

    def applicable?
      true
    end

    def generators_for(...)
      # :nocov:
      self.class.generators_for(...)
      # :nocov:
    end

    def generator_for(...)
      self.class.generator_for(...)
    end

    def dependencies
      []
    end

    def generate(elements_to_generate)
      dependencies.each do |dependency|
        elements_to_generate << dependency
      end

      # Render the template
      erb_template.result(binding)
    end

    def template_path
      # :nocov:
      raise "Subclass responsibility"
      # :nocov:
    end

    def absolute_template_path
      path = template_path

      if path.is_a?(::Array)
        path = path.join("/")
      end

      Pathname.new("#{templates_dir}/#{path}").cleanpath.to_s
    end

    def templates_dir
      # :nocov:
      "#{Dir.pwd}/templates"
      # :nocov:
    end

    def template_string
      File.read(absolute_template_path)
    end

    def erb_template
      # erb = ERB.new(template_string.gsub("\n<% end %>", "<% end %>"))
      erb = ERB.new(template_string)
      erb.filename = absolute_template_path
      erb
    end

    def path_to_root
      size = target_path.size - 1

      (["../"] * size).join
    end

    def method_missing(method_name, *, &)
      if relevant_manifest.respond_to?(method_name)
        relevant_manifest.send(method_name, *, &)
      else
        # :nocov:
        super
        # :nocov:
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      relevant_manifest.respond_to?(method_name, include_private)
    end

    def ==(other)
      relevant_manifest == other.relevant_manifest
    end

    def eql?(other)
      self == other
    end

    def hash
      relevant_manifest.hash
    end
  end
end
