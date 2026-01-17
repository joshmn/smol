# frozen_string_literal: true

require_relative "lib/smol/version"

Gem::Specification.new do |spec|
  spec.name = "smol"
  spec.version = Smol::VERSION
  spec.authors = ["Josh Brody"]
  spec.email = ["gems@josh.mn"]

  spec.summary = "A small, zero-dependency CLI and REPL framework for Ruby"
  spec.description = "Build CLI tools with commands, checks, and configuration. Supports both single-command execution and interactive REPL mode."
  spec.homepage = "https://github.com/joshmn/smol"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.4"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/joshmn/smol"
  spec.metadata["changelog_uri"] = "https://github.com/joshmn/smol/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ dist/ Gemfile .gitignore .github/ test/])
    end
  end
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "logger"
  spec.add_dependency "readline"
end
