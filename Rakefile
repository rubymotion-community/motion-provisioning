require 'bundler/gem_tasks'
require 'motion-provisioning'

Rake::Task[:build].enhance [:build_export_private_key] # make sure export_private_key is compiled prior to Bundler's "build" task so that it can be included in the gem package

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec, :tag) do |t, task_args|
    t.rspec_opts = "--tag #{task_args[:tag]}"
  end
rescue LoadError
end

desc "Generate the certificates needed by the test suite."
task :generate_certificates do
  FileUtils.mkdir_p('spec/fixtures')
  Dir.chdir('spec/fixtures') do
    # Create the root certs
    `openssl genrsa -out rootCA.p12 2048`
    `openssl req -x509 -new -nodes -key rootCA.p12 -sha256 -days 1024 -out rootCA.pem -subj "/C=US/ST=California/L=San Francisco/O=Apple Inc./OU=IT Department/CN=MotionProvisioning ROOT"`
    puts "Adding certificate to Keychain (sudo privileges required)"
    `sudo security add-trusted-cert -d -k "#{Dir.home}/Library/Keychains/login.keychain" rootCA.pem`
    `security import rootCA.pem`

    [:ios, :mac].each do |platform|
      [:development, :distribution].each do |type|
        generate_certificate(platform, type)
      end
    end
  end
end

# Generates a certificate for the specified platform and type
def generate_certificate(platform, type)
  `openssl genrsa -out #{platform}_#{type}_private_key.p12 2048`
  `openssl req -new -key #{platform}_#{type}_private_key.p12 -out #{platform}_#{type}.csr -subj "/C=US/ST=California/L=San Francisco/CN=#{platform} #{type}: MotionProvisioning/O=MotionProvisioning/OU=IT Department"`
  `openssl x509 -req -extfile openssl.conf -extensions 'my server exts' -in #{platform}_#{type}.csr -CA rootCA.pem -CAkey rootCA.p12 -CAcreateserial -outform der -out #{platform}_#{type}_certificate.cer -days 500 -sha256`
end

task :build_export_private_key do
  Dir.chdir('export_private_key') do
    system('clang -framework Security -framework CoreFoundation export_private_key.c -o export_private_key')
    FileUtils.mv('export_private_key', '../bin/')
  end
end

# Run this from time to time to ensure everything is running in the Real World
# like expected.
desc "Create all types of certificates and profiles using a real developer account."
task :production_test do
  require "bundler/setup"
  require "motion-provisioning"
  require "fileutils"

  MotionProvisioning.client

  num = rand(9999)
  ios_app_id = "com.hipbyte.iostest#{num}"
  ios_app = MotionProvisioning::Application.find_or_create(bundle_id: ios_app_id, name: "My iOS Test App")
  [:ios, :tvos].each do |platform|
    [:distribution, :adhoc, :development, :development_free].each do |type|
      free = type == :development_free
      type = :development if type == :development_free
      cert_type = type == :development ? :development : :distribution
      MotionProvisioning.certificate(type: cert_type, platform: :ios, free: free)
      MotionProvisioning.profile(bundle_identifier: ios_app_id,
        platform: platform,
        app_name: "My iOS Test App",
        type: type,
        free: free)
      FileUtils.rm(Dir.glob('provisioning/*.cer'))
    end
  end
  ios_app.delete!

  num = rand(9999)
  mac_app_id = "com.hipbyte.mactest#{num}"
  mac_app = MotionProvisioning::Application.find_or_create(bundle_id: mac_app_id, name: "My macOS Test App", mac: true)
  platform = :mac
  [:distribution, :development].each do |type|
    MotionProvisioning.certificate(type: type, platform: :mac)
    MotionProvisioning.profile(bundle_identifier: mac_app_id,
      platform: platform,
      app_name: "My macOS Test App",
      type: type)
    FileUtils.rm(Dir.glob('provisioning/*.cer'))
  end
  mac_app.delete!

end
