require_relative 'lib/cease/version'

Gem::Specification.new do |spec|
  spec.name          = "cease"
  spec.version       = Cease::VERSION
  spec.authors       = ["Sung Noh"]
  spec.email         = ["sung@dustybit.software"]

  spec.summary       = 'Evict unused code at some time in the future'
  spec.description   = 'Cease is a tool that detects blocks of code ' \
    'to be removed at a specified time.'
  spec.homepage      = 'https://github.com/DustyBitSoftware/cease'
  spec.license       = 'BSD-3-Clause'
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}).map { |path| File.basename(path) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'parser', '~> 3.0.0'
  spec.add_runtime_dependency 'git', '~> 1.10.0'
  spec.add_runtime_dependency 'rainbow', '~> 3.0.0'
  spec.add_runtime_dependency 'dotiw', '~> 5.3.2'
  spec.add_runtime_dependency 'tzinfo', '~> 2.0.4'
end
