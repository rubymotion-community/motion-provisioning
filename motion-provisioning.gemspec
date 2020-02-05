# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'motion-provisioning/version'

Gem::Specification.new do |spec|
  spec.name          = "motion-provisioning"
  spec.version       = MotionProvisioning::VERSION
  spec.authors       = ["Mark Villacampa", 'Andrew Havens']
  spec.email         = ["m@markvillacampa.com", 'email@andrewhavens.com']

  spec.summary       = %q{Simplified provisioning for RubyMotion iOS, tvOS and macOS apps.}
  spec.description   = %q{A small library that manages certificates and profiles automatically, from the command line, with minimal configuration.}
  spec.homepage      = "https://github.com/HipByte/motion-provisioning"
  spec.license       = "BSD"

  spec.files = Dir.glob("lib/**/*", File::FNM_DOTMATCH) +
               Dir.glob("bin/*") +
               Dir.glob("export_private_key/*") +
               %w(LICENSE.txt README.md)

  spec.require_paths = ["lib"]

  # Spaceship depends on the `plist` and `security` gems which we use too
  spec.add_dependency 'highline', '>= 1.7.2', '< 2.0.0' # user inputs (e.g. passwords)
  spec.add_dependency 'fastlane', '~> 2.113'

  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.2'
  spec.add_development_dependency 'webmock', '~> 3.7'
  spec.add_development_dependency 'simplecov', '~> 0.12'
end
