require "foobara/files_generator/bundler_actions"

RSpec.describe Foobara::FilesGenerator do
  let(:whatever_class) { stub_class "Whatever" }
  let(:generator) { interpolating_generator.new(whatever) }

  let(:command) { WriteWhateverToDisk.new(whatever:, output_directory:) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:whatever) { whatever_class.new }
  let(:output_directory) { "#{Dir.pwd}/tmp/whatever/" }

  let(:base_generator_class) do
    stub_class "BaseGenerator", described_class do
      class << self
        def manifest_to_generator_classes(manifest)
          case manifest
          when Whatever
            [
              InterpolatingGenerator
            ]
          else
            raise "wtf"
          end
        end

        def templates_dir = "#{__dir__}/fixtures/templates"
      end

      # TODO: do we really need this?
      def templates_dir = self.class.templates_dir
    end
  end

  let(:interpolating_generator) do
    stub_class "InterpolatingGenerator", base_generator_class do
      alias_method :whatever, :relevant_manifest

      def target_path = "some-file.txt"
      def template_path = "some-file.txt"

      def start_marker = "<!-- interpolating:begin -->"
      def end_marker = "<!-- interpolating:end -->"

      def applicable?
        File.exist?(template_path) && target_contents !~ /B/
      end

      def generate(_elements_to_generate)
        match = target_contents.match(/\n*C\n*/)
        new_entry = "B"

        content = [
          match.pre_match,
          start_marker,
          new_entry,
          end_marker
        ].join("\n") + [
          match,
          match.post_match
        ].join

        { content:, start_marker:, end_marker: }
      end

      def target_contents = File.read(template_path)
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

        paths_to_source_code
      end

      def base_generator = BaseGenerator
      def add_whatever_to_elements_to_generate = elements_to_generate << whatever
    end
  end

  let(:write_whatever_to_disk) do
    stub_class "WriteWhateverToDisk", Foobara::Generators::WriteGeneratedFilesToDisk do
      def self.generator_key = [:'preferred-key', :'deprecated-key']

      inputs do
        whatever Whatever, :required
        output_directory :string, :required
      end

      depends_on GenerateWhatever

      def execute
        delete_old_files_if_needed

        generate_whatever
        generate_generated_files_json

        write_all_files_to_disk

        stats
      end

      def generate_whatever
        Dir.chdir output_directory do
          self.paths_to_source_code = run_subcommand!(GenerateWhatever, whatever:)
        end
      end
    end
  end

  before do
    FileUtils.rm_rf(output_directory)
    FileUtils.cp_r("#{__dir__}/fixtures/existing-project", output_directory)

    whatever_class
    base_generator_class
    interpolating_generator
    generate_whatever
    write_whatever_to_disk
  end

  it "generates files" do
    expect(outcome).to be_success
    expect(result).to match(/\d+ files to /)

    expect(
      File.read("#{output_directory}/some-file.txt")
    ).to eq("A\n<!-- interpolating:begin -->\nB\n<!-- interpolating:end -->\nC\n")

    generated_files_json = File.read(File.join(output_directory, "preferred-key-generator.json"))
    generated_files_data = JSON.parse(generated_files_json)
    files = generated_files_data["files"].map { it["file_path"] }

    expect(files).to contain_exactly("some-file.txt")

    # let's see if it works when doing it twice...
    new_command = WriteWhateverToDisk.new(whatever:, output_directory:)
    new_outcome = new_command.run
    new_result = new_outcome.result

    expect(new_outcome).to be_success
    expect(new_result).to match(/\d+ files to /)

    expect(
      File.read("#{output_directory}/some-file.txt")
    ).to eq("A\n<!-- interpolating:begin -->\nB\n<!-- interpolating:end -->\nC\n")

    generated_files_json = File.read(File.join(output_directory, "preferred-key-generator.json"))
    generated_files_data = JSON.parse(generated_files_json)
    files = generated_files_data["files"].map { it["file_path"] }

    expect(files).to contain_exactly("some-file.txt")
  end
end
