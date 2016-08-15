module MotionProvisioning
  class Application
    # Finds or create app for the given bundle id and name
    def self.find_or_create(bundle_id: nil, name: nil, mac: false)
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
            exit(1)
          elsif e.to_s.include?("is not available")
            Utils.log("Error", "'#{bundle_id}' has already been taken. Please enter a different string.")
            exit(1)
          else
            raise(e)
          end
        end
      end

      app
    end
  end
end
