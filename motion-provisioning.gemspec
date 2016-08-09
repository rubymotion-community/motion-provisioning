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
  spec.description   = %q{Simplified provisioning for RubyMotion iOS, tvOS and macOS apps.}
  spec.homepage      = "https://github.com/HipByte/motion-provisioning"
  spec.license       = "BSD"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'spaceship'
  spec.add_dependency 'plist'
  spec.add_dependency 'security'
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.2.3'
  spec.add_development_dependency 'webmock', '~> 1.21.0'
  spec.add_development_dependency 'simplecov'
end
