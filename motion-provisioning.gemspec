# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'motion-provisioning/version'

Gem::Specification.new do |spec|
  spec.name          = "motion-provisioning"
  spec.version       = MotionProvisioning::VERSION
  spec.authors       = ["Mark Villacampa"]
  spec.email         = ["m@markvillacampa.com"]

  spec.summary       = %q{Simplified provisioning for RubyMotion iOS, tvOS and macOS apps.}
  spec.description   = %q{A small library that manages certificates and profiles automatically, from the command line, with minimal configuration.}
  spec.homepage      = "https://github.com/HipByte/motion-provisioning"
  spec.license       = "BSD"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|img)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'spaceship', '~> 0.30'
  spec.add_dependency 'plist', '~> 3.2'
  spec.add_dependency 'security', '~> 0.1'
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.2'
  spec.add_development_dependency 'webmock', '~> 1.21'
  spec.add_development_dependency 'simplecov', '~> 0.12'
end
