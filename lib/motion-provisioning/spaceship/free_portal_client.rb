module Spaceship
  class FreePortalClient < Spaceship::PortalClient
    XCODE_VERSION = '9.2 (9C40b)'

    def teams
      return @teams if @teams
      req = request(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/listTeams.action", nil, {
        'X-Xcode-Version' => XCODE_VERSION # necessary in order to list Xcode free team
      })
      @teams = parse_response(req, 'teams').sort_by do |team|
        [
          team['name'],
          team['teamId']
        ]
      end
    end

    def development_certificates(mac: false)
      paging do |page_number|
        r = request(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/listAllDevelopmentCerts.action?clientId=XABBG36SBA&teamId=#{team_id}", nil, {
          'X-Xcode-Version' => XCODE_VERSION # necessary in order to work with Xcode free team
        })
        parse_response(r, 'certificates')
      end
    end

    def provisioning_profiles_via_xcode_api(mac: false)
      req = request(:post) do |r|
        r.url("https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/listProvisioningProfiles.action")
        r.params = {
          teamId: team_id,
          includeInactiveProfiles: true,
          onlyCountLists: true
        }
        r.headers['X-Xcode-Version'] = XCODE_VERSION # necessary in order to work with Xcode free team
      end

      result = parse_response(req, 'provisioningProfiles')

      csrf_cache[Spaceship::Portal::ProvisioningProfile] = self.csrf_tokens

      result
    end

    def create_provisioning_profile!(name, distribution_method, app_id, certificate_ids, device_ids, mac: false, sub_platform: nil, template_name: nil)
      ensure_csrf(Spaceship::App)

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

    def devices(mac: false, include_disabled: false)
      paging do |page_number|
        r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/listDevices.action", {
          teamId: team_id,
          pageNumber: page_number,
          pageSize: page_size,
          sort: 'name=asc',
          includeRemovedDevices: include_disabled
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

    def create_app!(type, name, bundle_id, mac: false, enable_services: {})
      # We moved the ensure_csrf to the top of this method
      # as we got some users with issues around creating new apps
      # https://github.com/fastlane/fastlane/issues/5813
      ensure_csrf(Spaceship::Portal::App)

      ident_params = case type.to_sym
                     when :explicit
                       {
                         type: 'explicit',
                         # push: 'on',          # Not available to free teams
                         # inAppPurchase: 'on', # Not available to free teams
                         gameCenter: 'on'
                       }
                     when :wildcard
                       {
                         type: 'wildcard',
                       }
                     end

      params = {
        identifier: bundle_id,
        name: name,
        teamId: team_id
      }
      params.merge!(ident_params)

      enable_services.each do |k, v|
        params[v.service_id.to_sym] = v.value
      end

      ensure_csrf(Spaceship::App)

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
      ensure_csrf(Spaceship::Certificate)

      r = request_plist(:post, "https://developerservices2.apple.com/services/#{PROTOCOL_VERSION}/#{platform_slug(mac)}/submitDevelopmentCSR.action?clientId=XABBG36SBA&teamId=#{team_id}", {
        teamId: team_id,
        csrContent: csr
      })

      parse_response(r, 'certRequest')
    end

    private

    def request_plist(method, url_or_path = nil, params = nil, headers = {}, &block)
      headers['X-Xcode-Version'] = XCODE_VERSION
      headers['Accept'] = 'text/x-xml-plist'
      headers['User-Agent'] = USER_AGENT
      headers.merge!(csrf_tokens)

      if params
        headers['Content-Type'] = 'text/x-xml-plist'
        params = params.to_plist
      end

      send_request(method, url_or_path, params, headers, &block)
    end
  end
end
