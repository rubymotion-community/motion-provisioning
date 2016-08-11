module MotionProvisioning
  # Represents a .mobileprobision file on disk
  class MobileProvision

    attr_accessor :hash, :enabled_services, :certificates

    # @param path (String): Path to the .mobileprovision file
    def initialize(path)
      file = File.read(path)
      start_index = file.index("<?xml")
      end_index = file.index("</plist>") + 8
      length = end_index - start_index
      self.hash = Plist::parse_xml(file.slice(start_index, length))
      self.certificates = []
      self.enabled_services = []

      entitlements_keys = hash['Entitlements'].keys
      Service.constants.each do |constant_name|
        service = Service.const_get(constant_name)
        keys = service.mobileprovision_keys
        if (keys - entitlements_keys).empty?
          self.enabled_services << service
        end
      end

      hash['DeveloperCertificates'].each do |certificate|
        self.certificates << certificate.read
      end
    end

    def name
      hash['Name']
    end

    def devices
      hash['ProvisionedDevices'].map(&:downcase)
    end

    # Checks wether the .mobileprovision file is valid by checking its
    # expiration date, entitlements and certificates
    # @param certificate (String): Path to the certificate file
    # @param app_entitlements (Hash): A hash containing the app's entitlements
    # @return Boolean
    def valid?(certificate, app_entitlements)
      return false if hash['ExpirationDate'] < DateTime.now

      entitlements = hash['Entitlements']
      # Remove entitlements that are not relevant for
      # Always true in development mobileprovision
      entitlements.delete('get-task-allow')
      # Always true in distribution mobileprovision
      entitlements.delete('beta-reports-active')
      entitlements.delete('application-identifier')
      entitlements.delete('com.apple.developer.team-identifier')
      # Always present, usually "$teamidentifier.*"
      entitlements.delete('keychain-access-groups')
      entitlements.delete('aps-environment')

      if app_entitlements != entitlements
        missing_in_app = entitlements.to_a - app_entitlements.to_a
        if missing_in_app.any?
          Utils.log("Error", "These entitlements are present in the provisioning profile but not in your app configuration:")
          puts missing_in_app
        end

        missing_in_profile = app_entitlements.to_a - entitlements.to_a
        if missing_in_profile.any?
          Utils.log("Error", "These entitlements are present in your app configuration but not in your provisioning profile:")
          puts missing_in_profile
        end

        return false
      end

      if !certificates.include?(File.read(certificate))
        Utils.log("Warning", "Your provisioning profile does not include your certificate. Repairing...")
        return false
      end

      true
    end

  end
end
