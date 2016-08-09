module Spaceship
  class PortalClient < Spaceship::Client

    def distribution_certificates(mac: false)
      paging do |page_number|
        r = request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform_slug(mac)}/downloadDistributionCerts.action?clientId=XABBG36SBA&teamId=#{team_id}")
        parse_response(r, 'certificates')
      end
    end

    def development_certificates(mac: false)
      paging do |page_number|
        r = request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform_slug(mac)}/listAllDevelopmentCerts.action?clientId=XABBG36SBA&teamId=#{team_id}")
        parse_response(r, 'certificates')
      end
    end

    # Fix a bug in Fastlane where the slug is hardcoded to ios
    def create_certificate!(type, csr, app_id = nil)
      ensure_csrf

      mac = Spaceship::Portal::Certificate::MAC_CERTIFICATE_TYPE_IDS.keys.include?(type)

      r = request(:post, "account/#{platform_slug(mac)}/certificate/submitCertificateRequest.action", {
        teamId: team_id,
        type: type,
        csrContent: csr,
        appIdId: app_id # optional
      })
      parse_response(r, 'certRequest')
    end

  end
end
