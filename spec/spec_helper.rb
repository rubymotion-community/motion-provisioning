if ENV['SPEC_COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

if ENV['SPEC_PROFILER']
  require 'rspec-prof'
end

require 'motion-provisioning'
require 'json'
require 'stubbing'

ENV['MOTION_PROVISIONING_EMAIL'] = 'foo@example.com'
ENV['MOTION_PROVISIONING_PASSWORD'] = 'password'

def try_delete(path)
  FileUtils.rm_f(path) if File.exist? path
end

RSpec.configure do |config|
  config.before(:each) do
    Dir.glob('provisioning/*.{p12,cer,certSigningRequest,mobileprovision}').each { |f| try_delete(f) }
    Spaceship::Portal.client = nil
  end

  config.before(:each) do
    @start_timer = Time.now
  end

  config.after(:each) do
    RSpec.configuration.output_stream.puts "Spec ran in #{Time.now - @start_timer}s"
  end

  config.before(:all) do
    `security create-keychain -p "foo" motion-provisioning`
    $keychain = File.expand_path('~/Library/Keychains/motion-provisioning')
    try_delete(File.expand_path("/tmp/spaceship_itc_service_key.txt"))
  end

  config.after(:all) do
    `security delete-keychain motion-provisioning`
  end
end

def fixture_file(filename)
  File.read(File.join('spec', 'fixtures', filename))
end

if !`/Library/RubyMotion/bin/ios/deploy -D`.strip.empty?
  puts "Please disconnect all iOS devices from the computer before running the tests"
  abort
end

unless ENV["SPEC_DEBUG"]
  $stdout = $stderr = File.open("/tmp/motion_provisioning_tests", "w")
end

def delete_certificate(name)
  `security delete-certificate -c "#{name}" #{$keychain} 2>&1`
end

SPEC_CERTIFICATES = {
  ios: {
    development: {
      id: "12345",
      type_id: "5QPB9NHCEI",
      name: "ios development: MotionProvisioning",
      content: fixture_file('ios_development_certificate.cer'),
    },
    distribution: {
      id: "67890",
      type_id: "R58UK2EWSO",
      name: "ios distribution: MotionProvisioning",
      content: fixture_file('ios_distribution_certificate.cer'),
    }
  },
  mac: {
    development: {
      id: "12345",
      type_id: "749Y1QAGU7",
      name: "mac development: MotionProvisioning",
      content: fixture_file('mac_development_certificate.cer'),
    },
    distribution: {
      id: "67890",
      type_id: "HXZEUKP0FP",
      name: "mac distribution: MotionProvisioning",
      content: fixture_file('mac_distribution_certificate.cer'),
    }
  }
}

SPEC_CERTIFICATES[:tvos] = SPEC_CERTIFICATES[:ios].dup
