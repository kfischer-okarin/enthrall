# frozen_string_literal: true

require_relative "lib/enthrall/version"

Gem::Specification.new do |spec|
  spec.name = "enthrall"
  spec.version = Enthrall::VERSION
  spec.authors = ["Kevin Fischer"]
  spec.email = ["kevin@kf-labo.dev"]

  spec.summary = "Automation and acceptance test framework for DragonRuby GTK"
  spec.description = "Enthrall is an automation and acceptance test framework specifically designed for DragonRuby GTK applications, enabling you to write and run automated tests for your DragonRuby games."
  spec.homepage = "https://github.com/kfischer-okarin/enthrall"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kfischer-okarin/enthrall"
  spec.metadata["changelog_uri"] = "https://github.com/kfischer-okarin/enthrall/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github .claude appveyor Gemfile]) ||
        f == "CLAUDE.md"
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
