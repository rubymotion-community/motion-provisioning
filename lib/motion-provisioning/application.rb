module MotionProvisioning
  class Application

    # Finds or create app for the given bundle id and name
    def self.find_or_create(bundle_id: nil, name: nil, mac: mac = false)
      app = Spaceship::Portal::App.find(bundle_id, mac: mac)
      if app
        app = app.details if app.features.nil?
      else
        begin
          app = Spaceship::Portal::App.create!(bundle_id: bundle_id, name: name, mac: mac)
          app = app.details if app.features.nil?
        rescue Spaceship::Client::UnexpectedResponse => e
          if e.to_s.include?("is not a valid identifier")
            Utils.log("Error", "'#{bundle_id}' is not a valid identifier for an app. Please choose an identifier containing only alphanumeric characters, dots and asterisk")
            exit 1
          elsif e.to_s.include?("is not available")
            Utils.log("Error", "'#{bundle_id}' has already been taken. Please enter a different string.")
            exit 1
          else
            raise e
          end
        end
      end

      services = MotionProvisioning.services

      Disable all app services not enabled via entitlements
      app.enabled_features.each do |feature_id|
        # These services are always enabled and cannot be disabled
        next if ['inAppPurchase', 'gameCenter', 'push'].include?(feature_id)
        service = services.detect { |s| s.identifier == feature_id }
        if service.nil?
          Utils.log('Info', "Disabling unused app service '#{feature_id}' for '#{bundle_id}'")
          # To disable Data Protection we need to send an empty string as value
          value = feature_id == 'dataProtection' ? '' : false
          app.update_service(Spaceship::Portal::AppService.new(feature_id, value))
        end
      end

      # Enable all app services enabled via entitlements (or which have a different value)
      services.each do |service|
        value = service.identifier == 'dataProtection' ? 'complete' : true
        if app.features[service.identifier] != value
          Utils.log('Info', "Enabling app service '#{service.name.split("::").last}' for '#{bundle_id}'")
          app.update_service(Spaceship::Portal::AppService.new(service.identifier, value))
        end
      end

      app
    end
  end
end
