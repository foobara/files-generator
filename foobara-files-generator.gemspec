require_relative "src/version"

Gem::Specification.new do |spec|
  spec.name = "foobara-files-generator"
  spec.version = Foobara::FilesGenerator::VERSION
  spec.authors = ["Miles Georgi"]
  spec.email = ["azimux@gmail.com"]

  spec.summary = "Common code reused across code generator projects"
  spec.homepage = "https://github.com/foobara/files-generator"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "src/**/*",
    "LICENSE.txt"
  ]

  spec.add_dependency "foobara"

  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
end
