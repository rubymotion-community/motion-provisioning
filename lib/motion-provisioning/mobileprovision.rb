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

      if !certificates.include?(File.read(certificate))
        Utils.log("Warning", "Your provisioning profile does not include your certificate. Repairing...")
        return false
      end

      true
    end

  end
end
