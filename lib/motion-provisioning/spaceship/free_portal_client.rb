module Spaceship
  class FreePortalClient < Spaceship::PortalClient

    def create_provisioning_profile!(name, distribution_method, app_id, certificate_ids, device_ids, mac: false, sub_platform: nil)
      ensure_csrf

      params = {
        teamId: team_id,
        appIdId: app_id,
      }

      r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/downloadTeamProvisioningProfile.action", params)
      parse_response(r, 'provisioningProfile')
    end

    def download_provisioning_profile(profile_id, mac: false)
      r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/downloadProvisioningProfile.action", {
        teamId: team_id,
        provisioningProfileId: profile_id
      })
      a = parse_response(r, 'provisioningProfile')
      if a['encodedProfile']
        a['encodedProfile'].read
      end
    end

    def devices(mac: false)
      paging do |page_number|
        r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/listDevices.action", {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc'
        })
        parse_response(r, 'devices')
      end
    end

    def create_device!(device_name, device_id, mac: false)
      r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/addDevice.action", {
        teamId: team_id,
        deviceNumber: device_id,
        name: device_name
      })

      parse_response(r, 'device')
    end

    def apps(mac: false)
      paging do |page_number|
        r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/listAppIds.action?clientId=XABBG36SBA", {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc'
        })
        parse_response(r, 'appIds')
      end
    end

    def details_for_app(app)
      r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(app.mac?)}/getAppIdDetail.action", {
        teamId: team_id,
        identifier: app.app_id
      })
      parse_response(r, 'appId')
    end

    def create_app!(type, name, bundle_id, mac: false)
      params = {
        identifier: bundle_id,
        name: name,
        teamId: team_id
      }

      ensure_csrf

      r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/addAppId.action?clientId=XABBG36SBA", params)
      parse_response(r, 'appId')
    end

    def revoke_development_certificate(serial_number, mac: false)
      r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/revokeDevelopmentCert.action?clientId=XABBG36SBA", {
        teamId: team_id,
        serialNumber: serial_number,
      })
      parse_response(r, 'certRequests')
    end

    def create_development_certificate(csr, mac: false)
      ensure_csrf

      r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/submitDevelopmentCSR.action?clientId=XABBG36SBA&teamId=#{team_id}", {
        teamId: team_id,
        csrContent: csr
      })

      parse_response(r, 'certRequest')
    end

    private

    def ensure_csrf
      if csrf_tokens.count == 0
        # If we directly create a new resource (e.g. app) without querying anything before
        # we don't have a valid csrf token, that's why we have to do at least one request
        teams
      end
    end

    def request_plist(method, url_or_path = nil, params = nil, headers = {}, &block)
      headers['X-Xcode-Version'] = '7.3.1 (7D1014)'
      headers['Content-Type'] = 'text/x-xml-plist'
      headers['User-Agent'] = USER_AGENT
      headers.merge!(csrf_tokens)

      params = params.to_plist if params

      send_request(method, url_or_path, params, headers, &block)
    end
  end
end
