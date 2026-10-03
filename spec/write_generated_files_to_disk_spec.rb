RSpec.describe Foobara::Generators::WriteGeneratedFilesToDisk do
  let(:output_directory) { "#{__dir__}/../tmp/w" }
  let(:writer) { described_class.new(output_directory:) }

  describe "#run_cmd_and_return_output" do
    context "when the command doesn't exist" do
      let(:cmd) { "made_up_command_does_not_exist" }

      it "raises" do
        expect {
          writer.run_cmd_and_return_output(cmd)
        }.to raise_error(Foobara::Generators::WriteGeneratedFilesToDisk::CouldNotExecuteError)
      end
    end
  end

  describe "#run_cmd_and_write_output" do
    context "when the command doesn't exist" do
      let(:cmd) { "made_up_command_does_not_exist" }

      context "when raise_if_fails" do
        let(:raise_if_fails) { true }

        it "raises" do
          expect {
            writer.run_cmd_and_write_output(cmd, raise_if_fails:)
          }.to raise_error(Foobara::Generators::WriteGeneratedFilesToDisk::CouldNotExecuteError)
        end
      end

      context "when not raise_if_fails" do
        let(:raise_if_fails) { false }

        before do
          allow(writer).to receive(:warn)
        end

        it "does not raise" do
          expect {
            writer.run_cmd_and_write_output(cmd, raise_if_fails:)
          }.to_not raise_error
        end
      end
    end
  end

  describe "#generated_files_json_filename" do
    context "when .generator_key is nil" do
      it "is foobara-generated.json" do
        expect(writer.class.generator_key).to be_nil
        expect(writer.generated_files_json_filename).to eq("foobara-generated.json")
      end
    end
  end
end
