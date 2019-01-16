module MotionProvisioning
  class ProvisioningProfile

    attr_accessor :type, :platform

    def client
      MotionProvisioning.client
    end

    def provisioning_profile(bundle_id, app_name, platform, type)
      self.type = type
      self.platform = platform
      output_path = MotionProvisioning.output_path
      provisioning_profile_path = File.join(output_path, "#{bundle_id}_#{platform}_#{type}_provisioning_profile.mobileprovision")
      provisioning_profile_name = "(MotionProvisioning) #{bundle_id} #{platform} #{type}"
      certificate_type = type == :development ? :development : :distribution
      certificate_platform = platform == :mac ? :mac : :ios
      certificate_path = File.join(output_path, "#{certificate_platform}_#{certificate_type}_certificate.cer")
      if !File.exist?(certificate_path)
        Utils.log('Error', "Couldn't find the certificate in path '#{certificate_path}'.")
        Utils.log('Error', "Make sure you're configuring the certificate *before* the provisioning profile in the Rakefile.")
        abort
      end

      if File.exist?(provisioning_profile_path) && ENV['recreate_profile'].nil?
        mobileprovision = MobileProvision.new(provisioning_profile_path)
        if mobileprovision.valid?(certificate_path, MotionProvisioning.entitlements)
          Utils.log('Info', "Using provisioning profile '#{mobileprovision.name}'.")
          return provisioning_profile_path
        end
      end

      # ensure a client is created and logged in
      client

      app = Application.find_or_create(bundle_id: bundle_id, name: app_name, mac: platform == :mac)

      profile = profile_type.find_by_bundle_id(bundle_id: bundle_id, mac: platform == :mac, sub_platform: ('tvOS' if platform == :tvos)).detect do |profile|
        next if profile.platform.downcase.include?("tvos") && platform != :tvos
        next if !profile.platform.downcase.include?("tvos") && platform == :tvos
        profile.name == provisioning_profile_name
      end

      # Offer to register devices connected to the current computer
      force_repair = false
      if ENV['MOTION_PROVISIONING_NO_REGISTER_DEVICES'].nil? && [:development, :adhoc].include?(type) && [:ios, :tvos].include?(platform)
        ids = `/Library/RubyMotion/bin/ios/deploy -D`.split("\n")

        # If there is a profile, we check the device is included.
        # Otherwise check if the device is registered in the Developer Portal.
        if profile
          profile_devices = profile.devices.map(&:udid).map(&:downcase)
          ids.each do |id|
            next if profile_devices.include?(id.downcase)
            answer = Utils.ask("Info", "This computer is connected to an iOS device with ID '#{id}' which is not included in the profile. Do you want to register it? (Y/n):")
            if answer.yes?
              Utils.log('Info', "Registering device with ID '#{id}'")
              Spaceship::Portal::Device.create!(name: 'iOS Device', udid: id)
              force_repair = true
            end
          end
        else
          ids.each do |id|
            existing = Spaceship::Portal::Device.find_by_udid(id)
            next if existing
            answer = Utils.ask("Info", "This computer is connected to an iOS device with ID '#{id}' which is not registered in the Developer Portal. Do you want to register it? (Y/n):")
            if answer.yes?
              Utils.log('Info', "Registering device with ID '#{id}'")
              client.create_device!('iOS Device', id)
            end
          end
        end
      end

      certificates = if type == :development
          client.development_certificates(mac: platform == :mac).map { |c| Spaceship::Portal::Certificate.factory(c) }
        else
          certificate_platform = platform == :mac ? :mac : :ios
          certificate_sha1 = OpenSSL::Digest::SHA1.new(File.read(File.join(output_path, "#{certificate_platform}_distribution_certificate.cer")))
          cert = client.distribution_certificates(mac: platform == :mac).detect do |c|
            OpenSSL::Digest::SHA1.new(c['certContent'].read) == certificate_sha1
          end

          if cert.nil?
            Utils.log('Error', 'Your distribution certificate is invalid. Recreate it by setting the env variable "recreate_certificate=1" and running the command again.')
            abort
          end

          # Distribution profiles can only contain one certificate
          [Spaceship::Portal::Certificate.factory(cert)]
        end

      if profile.nil?
        sub_platform = platform == :tvos ? 'tvOS' : nil
        Utils.log('Info', 'Could not find any existing profiles, creating a new one.')

        begin
          profile = profile_type.create!(name: provisioning_profile_name, bundle_id: bundle_id,
            certificate: certificates , devices: nil, mac: platform == :mac, sub_platform: sub_platform)
        rescue => ex
          if ex.to_s.include?("Your team has no devices")
            Utils.log("Error", "Your team has no devices for which to generate a provisioning profile. Connect a device to use for development or manually add device IDs by running: rake \"motion-provisioning:add-device[device_name,device_id]\"")
            abort
          end
          raise ex
        end
      elsif profile.status != 'Active' || profile.certificates.map(&:id) != certificates.map(&:id) || force_repair
        Utils.log('Info', "Repairing provisioning profile '#{profile.name}'.")
        profile.certificates = certificates
        devices = case platform
          when :tvos then Spaceship::Device.all_apple_tvs
          when :mac then Spaceship::Device.all_macs
          else Spaceship::Device.all_ios_profile_devices
          end
        profile.devices = type == :distribution ? [] : devices
        profile = profile.repair!
      end

      Utils.log('Info', "Using provisioning profile '#{profile.name}'.")
      File.write(provisioning_profile_path, profile.download)
      provisioning_profile_path
    end

    # The kind of provisioning profile we're interested in
    def profile_type
      return @profile_type if @profile_type
      @profile_type = Spaceship::Portal.provisioning_profile.app_store
      @profile_type = Spaceship::Portal.provisioning_profile.in_house if client.in_house?
      @profile_type = Spaceship::Portal.provisioning_profile.ad_hoc if self.type == :adhoc
      @profile_type = Spaceship::Portal.provisioning_profile.development if self.type == :development
      @profile_type
    end
  end
end
