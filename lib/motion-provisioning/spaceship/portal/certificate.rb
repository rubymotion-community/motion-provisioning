module Spaceship
  module Portal
    class Certificate
      # The PLIST request for the free certificate returns the certificate content
      # in the certContent variable. It's stored in this attribute for later use.
      attr_accessor :motionprovisioning_certContent,
                    :motionprovisioning_serialNumber
    end
  end
end
