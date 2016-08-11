module MotionProvisioning
  class Service
    attr_accessor :value

    def initialize(value)
      self.value = value
    end

    def identifier
      self.class.identifier
    end

    def to_hash
      { self.class.mobileprovision_keys.first => value }
    end

    def self.mobileprovision_keys
      []
    end

    def self.identifier
    end

    # Add iCloud feature to app id
    # Add iCloud container to app id
    # Add iCloud entitlement to entitlements file
    # Link CloudKit.framework
    # <key>com.apple.developer.ubiquity-kvstore-identifier</key>
    # <string>98ZHTS9H6G.*</string>
    # <key>com.apple.developer.icloud-services</key>
    # <string>*</string>
    # <key>com.apple.developer.ubiquity-container-identifiers</key>
    # <array>
    # <string>iCloud.com.hipbyte.testicloudcontainer</string>
    # </array>

    # <key>com.apple.developer.icloud-container-environment</key>
    # <array>
    # <string>Development</string>
    # <string>Production</string>
    # </array>

    # <key>com.apple.developer.icloud-container-identifiers</key>
    # <array>
    # <string>iCloud.com.hipbyte.testicloudcontainer</string>
    # </array>
    # <key>com.apple.developer.icloud-container-development-container-identifiers</key>
    # <array>
    # <string>iCloud.com.hipbyte.testicloudcontainer</string>
    # </array>
    class Cloud < Service

      attr_accessor :icloud_services, :icloud_identifiers

      def initialize(services, identifiers)
        self.icloud_services = services
        self.icloud_indentifiers = identifier
      end

      def self.mobileprovision_keys
        [
          'com.apple.developer.icloud-services',
          'com.apple.developer.ubiquity-kvstore-identifier',
          'com.apple.developer.ubiquity-container-identifiers',
          'com.apple.developer.icloud-container-environment',
          'com.apple.developer.icloud-container-identifiers',
          'com.apple.developer.icloud-container-development-container-identifiers',
        ]
      end

      def self.identifier
        'iCloud'
      end

      def to_hash
	{
	  'com.apple.developer.icloud-services' => self.icloud_services,
          'com.apple.developer.ubiquity-kvstore-identifier' => "teamidentifier.bundleid",
          'com.apple.developer.ubiquity-container-identifiers' => [iCloud.bundleid],
          'com.apple.developer.icloud-container-identifiers' => [iCloud.bundleid],
	}
      end
    end

    # Add Push Notifications feature to app id
    # Add Push Notifications entitlement to entitlements file
    # <key>aps-environment</key>
    # <string>production</string>
    class PushNotification < Service
      def self.mobileprovision_keys
        ['aps_environment']
      end

      def self.identifier
        'push'
      end
    end

    # Add Game Center feature to app id
    # Link GameKit.framework
    # Add GameKit key to info.plist
    class GameCenter < Service
    end

    # Add Wallet feature to app id
    # Add the Pass Types to your entitlements file
    # Link PassKit.framework
    # <key>com.apple.developer.pass-type-identifiers</key>
    # <array>
    # <string>98ZHTS9H6G.*</string>
    # </array>
    class Wallet < Service
      def self.mobileprovision_keys
        ['com.apple.developer.pass-type-identifiers']
      end

      def self.identifier
        'pass'
      end
    end

    # Add Apple Pay entitlement to entitlements file
    # Add Apple Pay feature to app id
    # Add Metchand IDs to your app id
    # <string>merchant.com.hipbyte.testmerchantid</string>
    # </array>
    class ApplePay < Service
      def self.mobileprovision_keys
        ['merchant.com.hipbyte.testmerchantid']
      end

      def self.identifier
        'OM633U5T5G'
      end
    end

    # Add In-App Purchase feature to app id
    # Link StoreKit.framework
    # <key>com.apple.developer.in-app-payments</key>
    # <array>
    # <string>merchant.com.hipbyte.testmerchantid</string>
    # </array>
    class InAppPurchase < Service
      def self.mobileprovision_keys
        ['com.apple.developer.in-app-payments']
      end

      def self.identifier
        'inAppPurchase'
      end
    end

    # Link MapKit.framework
    # Add Routing Type keys to info.plist
    class Maps < Service
    end

    # Link NetworkExtension.framework
    # Add Personal VPN feature to app id
    # Add Personal VPN entitlement to entitlements file
    # <key>com.apple.developer.networking.vpn.api</key>
    # <array>
    # <string>allow-vpn</string>
    # </array>
    class PersonalVPN < Service
      def self.mobileprovision_keys
        ['com.apple.developer.networking.vpn.api']
      end

      def self.identifier
        'V66P55NK2I'
      end
    end

    # Add Keychain Sharing feature to app id
    # Add Keychain Sharing entitlement to entitlements file
    # <key>keychain-access-groups</key>
    # <array>
    # <string>98ZHTS9H6G.*</string>
    # </array>
    class KeychainSharing < Service
      def self.mobileprovision_keys
        ['keychain-access-groups']
      end

      def self.identifier
        'LPLF93JG7M'
      end
    end

    # Add Background Modes keys to info.plist
    class BackgroundModes < Service
    end

    # Add Inter-App Audio feature to app id
    # Add Inter-App Audio to your entitlements file
    # Link AudioToolbox.framework
    # <key>inter-app-audio</key>
    # <true/>
    class InterAppAudio < Service
      def self.mobileprovision_keys
        ['inter-app-audio']
      end

      def self.identifier
        'IAD53UNK2F'
      end
    end

    # Add Associated Domains feature to app id
    # Add Associated Domains to your entitlements file
    # <key>com.apple.developer.associated-domains</key>
    # <string>*</string>
    class AssociatedDomains < Service
      attr_accessor :domains

      def initialize(domains)
        self.domains = domains
      end

      def self.mobileprovision_keys
        ['com.apple.developer.associated-domains']
      end

      def self.identifier
        'SKC3T5S89Y'
      end

      def to_hash
        { self.class.mobileprovision_keys.first => domains }
      end
    end

    # Add App Groups feature to app id
    # Add App Groups to app id
    # Add App Groups to your entitlements file
    # <key>com.apple.security.application-groups</key>
    # <array>
    # <string>group.com.hipbyte.testgroup</string>
    # </array>
    class AppGroups < Service
      attr_accessor :groups

      def initialize(groups)
        self.groups = groups
      end

      def self.mobileprovision_keys
        ['com.apple.security.application-groups']
      end

      def self.identifier
        'APG3427HIY'
      end

      def to_hash
        { self.class.mobileprovision_keys.first => groups }
      end
    end

    # Add HomeKit feature to app id
    # Add HomeKit to your entitlements file
    # Link HomeKit.framework
    # <key>com.apple.developer.homekit</key>
    # <true/>
    class HomeKit < Service
      def self.mobileprovision_keys
        ['com.apple.developer.homekit']
      end

      def self.identifier
        'homeKit'
      end
    end

    # Add Data Protection feature to app id
    # Add Data Protection to your entitlements file
    # <key>com.apple.developer.default-data-protection</key>
    # <string>NSFileProtectionComplete</string>
    class DataProtection < Service

      def initialize(value)
	self.value = case value
	when 'NSFileProtectionComplete' then 'complete'
	when 'NSFileProtectionUnlessOpen' then 'unlessopen'
	when 'NSFileProtectionCompleteUntilFirstUserAuthentication' then 'untilfirstauth'
	end
      end

      def self.mobileprovision_keys
        ['com.apple.developer.default-data-protection']
      end

      def self.identifier
        'dataProtection'
      end
    end

    # Add HealthKit feature to app id
    # Add HealthKit to your entitlements file
    # Add HealthKit to your info plist
    # Link HealthKit.framework
    # <key>com.apple.developer.healthkit</key>
    # <true/>
    class HealthKit < Service
      def self.mobileprovision_keys
        ['com.apple.developer.healthkit']
      end

      def self.identifier
        'HK421J6T7P'
      end
    end

    # Add Wireless Accessory Configuration feature to app id
    # Add Wireless Accessory Configuration to your entitlements file
    # Link ExternalAccessory.framework
    # <key>com.apple.external-accessory.wireless-configuration</key>
    # <true/>
    class WirelesssAccessoryConfiguration < Service
      def self.mobileprovision_keys
        ['com.apple.external-accessory.wireless-configuration']
      end

      def self.identifier
        'WC421J6T7P'
      end
    end

    # <key>com.apple.developer.siri</key>
    # <true/>
    class Siri < Service
      def self.mobileprovision_keys
        ['com.apple.developer.siri']
      end

      def self.identifier
        'SI015DKUHP'
      end
    end

    # only dev
      # <key>get-task-allow</key>
      # <false/>
      # <key>application-identifier</key>
      # <string>98ZHTS9H6G.com.hipbyte.test</string>

      # <key>com.apple.developer.team-identifier</key>
      # <string>98ZHTS9H6G</string>
    # only appstore distribution
      # <key>beta-reports-active</key>
      # <true/>
  end
end
