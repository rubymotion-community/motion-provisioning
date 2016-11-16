module MotionProvisioning
  class Certificate
    attr_accessor :type, :output_path, :platform

    def client
      MotionProvisioning.client
    end

    def mac?
      self.platform == :mac
    end

    def certificate_name(type, platform)
      self.type = type
      self.platform = platform
      self.output_path = MotionProvisioning.output_path
      certificate_path = File.join(output_path, "#{platform}_#{type}_certificate.cer")
      private_key_path = File.join(output_path, "#{platform}_#{type}_private_key.p12")

      # First check if there is a certificate and key file, and if it is installed
      identities = available_identities
      if File.exist?(certificate_path) && File.exist?(private_key_path) && ENV['recreate_certificate'].nil?
        fingerprint = sha1_fingerprint(certificate_path)
        installed_cert = identities.detect { |e| e[:fingerprint] == fingerprint }
        if installed_cert
          Utils.log("Info", "Using certificate '#{installed_cert[:name]}'.")
          return installed_cert[:name]
        else
          # The certificate is not installed, so we install the cert and the key
          import_file(private_key_path)
          import_file(certificate_path)
          name = common_name(certificate_path)
          Utils.log("Info", "Using certificate '#{name}'.")
          return name
        end
      end

      # Make sure a client is created and logged in
      client

      # Lets see if any of the user certificates is in the keychain
      installed_certificate = nil
      if !certificates.empty?
        installed_certs_sha1 = identities.map { |e| e[:fingerprint] }
        installed_certificate = certificates.detect do |certificate|
          sha1 = OpenSSL::Digest::SHA1.new(certificate.motionprovisioning_certContent || certificate.download_raw)
          installed_certs_sha1.include?(sha1.to_s.upcase)
        end
      end

      # There are no certificates in the server so we create a new one
      if certificates.empty?
        Utils.log("Warning", "Couldn't find any existing certificates... creating a new one.")
        if certificate = create_certificate
          return common_name(certificate)
        else
          Utils.log("Error", "Something went wrong when trying to create a new certificate.")
          abort
        end
      # There are certificates in the server, but none is installed locally. Revoke all and create a new one.
      elsif installed_certificate.nil?
        Utils.log("Error", "None of the available certificates (#{certificates.count}) is installed on the local machine. Revoking...")

        # For distribution, ask before revoking
        if self.type == :distribution
          answer = Utils.ask("Info", "There are #{certificates.count} distribution certificates in your account, but none installed locally.\n" \
                    "Before revoking and creating a new one, ask other team members who might have them installed to share them with you.\n" \
                    "Do you want to continue revoking the certificates? (Y/n):")
          abort if answer.no?
        end

        # Revoke all and create new one
        if MotionProvisioning.free
          certificates.each do |certificate|
            client.revoke_development_certificate(certificate.motionprovisioning_serialNumber)
          end
        else
          certificates.each(&:revoke!)
        end

        if certificate = create_certificate
          return common_name(certificate)
        else
          Utils.log("Error", "Something went wrong when trying to create a new certificate...")
          abort
        end
      # There are certificates on the server, and one of them is installed locally.
      else
        Utils.log("Info", "Found certificate '#{installed_certificate.name}' which is installed in the local machine.")

        path = store_certificate_raw(installed_certificate.motionprovisioning_certContent || installed_certificate.download_raw)

        password = Utils.ask_password("Info", "Exporting private key from Keychain for certificate '#{installed_certificate.name}'. Choose a password (you will be asked for this password when importing this key into the Keychain in another machine):")
        private_key_contents = private_key(common_name(path), sha1_fingerprint(path), password)
        File.write(private_key_path, private_key_contents)

        # This certificate is installed on the local machine
        Utils.log("Info", "Using certificate '#{installed_certificate.name}'.")

        common_name(path)
      end
    end

    # All certificates of this type
    def certificates
      @certificates ||= begin
        if MotionProvisioning.free
          client.development_certificates(mac: mac?).map do |cert|
            certificate = Spaceship::Portal::Certificate.factory(cert)
            certificate.motionprovisioning_certContent = cert['certContent'].read
            certificate.motionprovisioning_serialNumber = cert['serialNumber']
            certificate
          end
        else
          certificates = certificate_type.all
          # Filter out development certificates belonging to other team members
          if self.type == :development
            user_id = MotionProvisioning.team['currentTeamMember']['teamMemberId']
            certificates.select! { |c| c.owner_id == user_id }
          end
          certificates
        end
      end
    end

    # The kind of certificate we're interested in
    def certificate_type
      cert_type = nil
      case platform
      when :ios, :tvos
        cert_type = Spaceship.certificate.production
        cert_type = Spaceship.certificate.in_house if Spaceship.client.in_house?
        cert_type = Spaceship.certificate.development if self.type == :development
      when :mac
        cert_type = Spaceship.certificate.mac_development
        cert_type = Spaceship.certificate.mac_app_distribution if self.type == :distribution
        cert_type = Spaceship.certificate.developer_i_d_application if self.type == :developer_id
      end
      cert_type
    end

    def create_certificate_signing_request
      $motion_provisioninig_csr || Spaceship.certificate.create_certificate_signing_request
    end

    def create_certificate
      # Create a new certificate signing request
      csr, pkey = create_certificate_signing_request

      # Store all that onto the filesystem
      request_path = File.expand_path(File.join(self.output_path, "#{platform}_#{type}.certSigningRequest"))
      File.write(request_path, csr.to_pem)

      private_key_path = File.expand_path(File.join(self.output_path, "#{platform}_#{type}_private_key.p12"))
      File.write(private_key_path, pkey.export)

      # Use the signing request to create a new distribution certificate
      begin
        certificate = nil
        certificate_attrs = nil
        if MotionProvisioning.free
          certificate_attrs = client.create_development_certificate(csr.to_pem)
          # Fetch the certificate again because the response does not contain
          # the certContent key
          certificate_attrs = client.development_certificates(mac: mac?).detect do |cert|
            cert['certificateId'] == certificate_attrs['certificateId']
          end
          certificate_attrs['certificateTypeDisplayId'] = certificate_attrs['certificateType']['certificateTypeDisplayId']
          certificate = Spaceship::Portal::Certificate.factory(certificate_attrs)
          certificate.motionprovisioning_certContent = certificate_attrs['certContent'].read
          certificate
        else
          certificate = certificate_type.create!(csr: csr)
        end
      rescue => ex
        if ex.to_s.include?("You already have a current")
          FileUtils.rm(private_key_path)
          FileUtils.rm(request_path)
          Utils.log("Error", "Could not create another certificate, reached the maximum number of available certificates. Manually revoke certificates in the Developer Portal.")
          abort
        end
        raise ex
      end
      Utils.log("Info", "Successfully created certificate.")

      cert_path = store_certificate_raw(certificate.motionprovisioning_certContent || certificate.download_raw)

      # Import all the things into the Keychain
      import_file(private_key_path)
      import_file(cert_path)
      Utils.log("Info", "Successfully installed certificate.")

      if self.type == :distribution
        Utils.log("Warning", "You have just created a distribution certificate. These certificates must be shared with other team members by sending them the private key (.p12) and certificate (.cer) files in your output folder and install them in the keychain.")
      else
        Utils.log("Warning", "You have just created a development certificate. If you want to use this certificate on another machine, transfer the private key (.p12) and certificate (.cer) files in your output folder and install them in the keychain.")
      end
      Utils.ask("Info", "Press any key to continue...")

      cert_path
    end

    def store_certificate_raw(raw_data)
      path = File.expand_path(File.join(self.output_path, "#{platform}_#{type}_certificate.cer"))
      File.write(path, raw_data)
      path
    end

    def available_identities
      ids = []
      keychain = $keychain || "#{Dir.home}/Library/Keychains/login.keychain"
      available = `security find-identity -v -p codesigning #{keychain}`
      available.split("\n").each do |current|
        next if current.include? "REVOKED"
        begin
          id = current.match(/.*\) (.*) \"(.*)\"/)
          ids << {
            fingerprint: id[1],
            name: id[2]
          }
        rescue
          # the last line does not match
        end
      end
      ids
    end

    def sha1_fingerprint(path)
      result = `openssl x509 -in "#{path}" -inform der -noout -sha1 -fingerprint`
      begin
        result = result.match(/SHA1 Fingerprint=(.*)/)[1]
        result.delete!(':')
        return result
      rescue
        Utils.log("Error", "Error parsing certificate '#{path}'")
      end
    end

    def common_name(path)
      result = `openssl x509 -in "#{path}" -inform der -noout -sha1 -subject`
      begin
        return result.match(/\/CN=(.*?)\//)[1]
      rescue
        Utils.log("Error", "Error parsing certificate '#{path}'")
      end
    end

    def import_file(path)
      unless File.exist?(path)
        Utils.log("Error", "Could not find file '#{path}'")
        abort
      end

      keychain = $keychain || "#{Dir.home}/Library/Keychains/login.keychain"

      command = "security import #{path.shellescape} -k '#{keychain}' -P ''"
      command << " -T /usr/bin/codesign"
      command << " -T /usr/bin/security"

      `#{command} 2>&1`
    end

    def private_key(name, fingerprint, password)
      export_private_key = File.join(File.expand_path(__dir__), '../../bin/export_private_key')
      `#{export_private_key} "#{name}" "#{fingerprint}" "#{password}"`.strip
    end
  end
end
