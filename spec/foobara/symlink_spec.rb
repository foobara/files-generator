RSpec.describe Foobara::FilesGenerator::Symlink do
  describe ".supported?" do
    it "is a boolean" do
      is_supported = described_class.supported?

      expect(is_supported).to be_a_boolean
    end
  end
end
