module Spaceship
  class PortalClient < Spaceship::Client

    def distribution_certificates(mac: false)
      paging do |page_number|
        r = request(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/downloadDistributionCerts.action?clientId=XABBG36SBA&teamId=#{team_id}")
        parse_response(r, 'certificates')
      end
    end

    def development_certificates(mac: false)
      paging do |page_number|
        r = request(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/listAllDevelopmentCerts.action?clientId=XABBG36SBA&teamId=#{team_id}")
        parse_response(r, 'certificates')
      end
    end
  end
end
