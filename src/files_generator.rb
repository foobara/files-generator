require "erb"

module Foobara
  class FilesGenerator
    include TruncatedInspect

    class << self
      def manifest_to_generator_classes(_manifest)
        # simplecov:disable
        raise "subclass responsibility"
        # simplecov:enable
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
        # simplecov:disable
        raise "expected a .erb extension. Maybe override #target_path"
        # simplecov:enable
      end
    end

    def target_dir
      target_path[0..-2]
    end

    def applicable?
      true
    end

    def generators_for(...)
      # simplecov:disable
      self.class.generators_for(...)
      # simplecov:enable
    end

    def generator_for(...)
      self.class.generator_for(...)
    end

    def dependencies
      []
    end

    def dependencies_to_generate
      if dependencies.is_a?(::Set)
        dependencies
      else
        Util.array(dependencies)
      end
    end

    def generate(elements_to_generate)
      dependencies_to_generate.each do |dependency|
        elements_to_generate << dependency
      end

      # Render the template
      erb_template.result(binding)
    end

    def template_path
      # simplecov:disable
      raise "Subclass responsibility"
      # simplecov:enable
    end

    def absolute_template_path
      path = template_path

      if path.is_a?(::Array)
        path = path.join("/")
      end

      Pathname.new("#{templates_dir}/#{path}").cleanpath.to_s
    end

    def templates_dir
      # simplecov:disable
      "#{Dir.pwd}/templates"
      # simplecov:enable
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
        # simplecov:disable
        super
        # simplecov:enable
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      relevant_manifest.respond_to?(method_name, include_private)
    end

    def ==(other)
      self.class == other.class && relevant_manifest == other.relevant_manifest
    end

    def eql?(other)
      self == other
    end

    def hash
      relevant_manifest.hash
    end
  end
end
