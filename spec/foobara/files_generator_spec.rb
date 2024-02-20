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

  let(:foo_class) do
    stub_class "Foo" do
      attr_accessor :foo

      def initialize(foo)
        self.foo = foo
      end

      def ==(other)
        other.is_a?(Foo) && foo == other.foo
      end

      def eql?(other)
        self == other
      end

      def hash
        foo.hash
      end
    end
  end

  let(:bar_class) do
    stub_class "Bar" do
      attr_accessor :bar

      def initialize(bar)
        self.bar = bar
      end

      def ==(other)
        other.is_a?(Foo) && bar == other.bar
      end

      def eql?(other)
        self == other
      end

      def hash
        bar.hash
      end
    end
  end

  let(:command) { WriteWhateverToDisk.new(whatever:, output_directory:) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:whatever) { whatever_class.new(foo, bar) }
  let(:foo) { foo_class.new("fooooo") }
  let(:bar) { bar_class.new("barrrr") }
  let(:output_directory) { "#{Dir.pwd}/tmp/whatever/" }

  let(:whatever_generator1) do
    stub_class "WhateverGenerator1", described_class do
      alias_method :whatever, :relevant_manifest

      class << self
        def manifest_to_generator_classes(manifest)
          case manifest
          when Whatever
            [
              WhateverGenerator1,
              WhateverGenerator2
            ]
          when Foo
            FooGenerator
          when Bar
            BarGenerator
          end
        end
      end

      def target_path
        ["whatevers1", "#{foo.foo}.txt"]
      end

      def template_path
        ["spec", "fixtures", "templates", "whatever1.txt.erb"]
      end

      def dependencies
        [
          FooGenerator.new(foo),
          bar
        ]
      end
    end
  end

  let(:whatever_generator2) do
    stub_class "WhateverGenerator2", described_class do
      alias_method :whatever, :relevant_manifest

      def target_path
        ["whatevers2", "#{bar.bar}.txt"]
      end

      def template_path
        ["spec", "fixtures", "templates", "whatever2.txt.erb"]
      end
    end
  end

  let(:foo_generator) do
    stub_class "FooGenerator", described_class do
      alias_method :foo, :relevant_manifest

      def target_path
        ["foos", "#{foo.foo}.txt"]
      end

      def template_path
        ["spec", "fixtures", "templates", "foo.txt.erb"]
      end
    end
  end
  let(:bar_generator) do
    stub_class "BarGenerator", described_class do
      alias_method :bar, :relevant_manifest

      def target_path
        ["bars", "#{bar.bar}.txt"]
      end

      def template_path
        ["spec", "fixtures", "templates", "bar.txt.erb"]
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
        WhateverGenerator1
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
    whatever_generator1
    whatever_generator2
    foo_generator
    bar_generator
    generate_whatever
    write_whatever_to_disk
  end

  it "generates files" do
    expect(outcome).to be_success
    expect(result).to be_a(Hash)

    expect(
      File.read("#{output_directory}whatevers1/fooooo.txt").chomp
    ).to eq("whatever1!\n\nFoo is #{foo.foo} and bar is #{bar.bar}")
    expect(
      File.read("#{output_directory}whatevers2/barrrr.txt").chomp
    ).to eq("whatever2!\n\nFoo is #{foo.foo} and bar is #{bar.bar}")
    expect(
      File.read("#{output_directory}foos/fooooo.txt").chomp
    ).to eq("Foo is #{foo.foo}")
    expect(
      File.read("#{output_directory}bars/barrrr.txt").chomp
    ).to eq("Bar is #{bar.bar}")
    expect(JSON.parse(File.read("#{output_directory}foobara-generated.json"))).to eq(
      [
        "bars/barrrr.txt",
        "foos/fooooo.txt",
        "whatevers1/fooooo.txt",
        "whatevers2/barrrr.txt"
      ]
    )
  end
end
