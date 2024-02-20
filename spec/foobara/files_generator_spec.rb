RSpec.describe Foobara::FilesGenerator do
  let(:whatever_class) do
    stub_class "Whatever" do
      attr_accessor :foo, :bar

      def initialize(foo, bar)
        self.foo = foo
        self.bar = bar
      end

      def ==(other)
        other.is_a?(Whatever) && foo == other.foo && bar == other.bar
      end

      def eql?(other)
        self == other
      end

      def hash
        [foo, bar].hash
      end
    end
  end

  let(:command) { WriteWhateverToDisk.new(whatever:, output_directory:) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:whatever) { whatever_class.new(foo, bar) }
  let(:foo) { "fooooo" }
  let(:bar) { "barrrr" }
  let(:output_directory) { "#{Dir.pwd}/tmp/whatever/" }

  let(:whatever_generator) do
    stub_class "WhateverGenerator", described_class do
      alias_method :whatever, :relevant_manifest

      class << self
        def manifest_to_generator_classes(manifest)
          case manifest
          when Whatever
            WhateverGenerator
          end
        end
      end
      def target_path
        ["whatevers", "#{foo}.txt"]
      end

      def template_path
        ["spec", "fixtures", "templates", "whatever.txt.erb"]
      end

      def ==(_other)
        whatever == other.whatever
      end

      def hash
        whatever.hash
      end
    end
  end

  let(:generate_whatever) do
    stub_class "GenerateWhatever", Foobara::Generators::Generate do
      inputs whatever: :duck

      def execute
        add_whatever_to_elements_to_generate

        each_element_to_generate do
          generate_element
        end

        generate_generated_files_json

        paths_to_source_code
      end

      def base_generator
        WhateverGenerator
      end

      def templates_dir
        "#{Dir.pwd}/spec/fixtures/templates"
      end

      def add_whatever_to_elements_to_generate
        elements_to_generate << whatever
      end
    end
  end

  let(:write_whatever_to_disk) do
    stub_class "WriteWhateverToDisk", Foobara::Generators::WriteGeneratedFilesToDisk do
      inputs do
        whatever :duck
        output_directory :string, :required
      end

      depends_on GenerateWhatever

      def execute
        generate_whatever
        delete_old_files_if_needed
        write_all_files_to_disk

        paths_to_source_code
      end

      def generate_whatever
        self.paths_to_source_code = run_subcommand!(GenerateWhatever, whatever:)
      end
    end
  end

  before do
    whatever_generator
    generate_whatever
    write_whatever_to_disk
  end

  it "generates files" do
    expect(outcome).to be_success
    expect(result).to be_a(Hash)

    expect(File.read("#{output_directory}/whatevers/#{foo}.txt").chomp).to eq("Foo is #{foo} and bar is #{bar}")
  end
end
