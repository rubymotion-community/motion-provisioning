require 'webmock/rspec'
require 'base64'

def adp_read_fixture_file(filename)
  File.read(File.join('spec', 'portal', 'fixtures', filename))
end

# # Optional: enterprise
# def adp_enterprise_stubbing
#   stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/ios/certificate/listCertRequests.action").
#     with(body: { "pageNumber" => "1", "pageSize" => "500", "sort" => "certRequestStatusCode=asc", "teamId" => "XXXXXXXXXX", "types" => "9RQEK7MSXA" }).
#     to_return(status: 200, body: adp_read_fixture_file(File.join("enterprise", "listCertRequests.action.json")), headers: { 'Content-Type' => 'application/json' })

#   stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/ios/profile/createProvisioningProfile.action").
#     with(body: { "appIdId" => "2UMR2S6PAA", "certificateIds" => "Q82WC5JRE9", "distributionType" => "inhouse", "provisioningProfileName" => "Delete Me", "teamId" => "XXXXXXXXXX" }).
#     to_return(status: 200, body: adp_read_fixture_file('create_profile_success.json'), headers: { 'Content-Type' => 'application/json' })
# end

# Optional: Team Selection
def adp_stub_multiple_teams
  stub_request(:post, 'https://developerservices2.apple.com/services/QH65B2/listTeams.action').
    to_return(status: 200, body: adp_read_fixture_file('listTeams_multiple.action.json'), headers: { 'Content-Type' => 'application/json' })
end

def stub_login
  stub_request(:get, 'https://itunesconnect.apple.com/itc/static-resources/controllers/login_cntrl.js').
    to_return(status: 200, body: "itcServiceKey = '1234567890'")
  stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa").
    to_return(status: 200, body: "")
  stub_request(:get, "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/wa/route?noext=true").
    to_return(status: 200, body: "")

  # Actual login
  stub_request(:post, "https://idmsa.apple.com/appleauth/auth/signin?widgetKey=1234567890").
    with(body: { "accountName" => "foo@example.com", "password" => "password", "rememberMe" => true }.to_json).
    to_return(status: 200, body: '{}', headers: { 'Set-Cookie' => "myacinfo=abcdef;" })

  stub_request(:get, "https://developer.apple.com/account/").
    to_return(status: 200, body: nil,
    headers: { 'Location' => "https://idmsa.apple.com/IDMSWebAuth/login?&appIdKey=aaabd3417a7776362562d2197faaa80a8aaab108fd934911bcbea0110d07faaa&path=%2F%2Fmembercenter%2Findex.action" })

  stub_request(:post, 'https://developerservices2.apple.com/services/QH65B2/listTeams.action').
    to_return(status: 200, body: adp_read_fixture_file('listTeams.action.json'), headers: { 'Content-Type' => 'application/json' })
end

def stub_create_profile(type, platform)
  normalized_platform = platform == :mac ? :mac : :ios

  distribution_type = case type
                      when :distribution then "store"
                      when :development then "limited"
                      when :adhoc then "adhoc"
                      end
  certificate_type = type == :development ? :development : :distribution

  body = {
    "appIdId"=>"L42E9BTRAA",
    "certificateIds" => SPEC_CERTIFICATES[normalized_platform][certificate_type][:id],
    "distributionType" => distribution_type,
    "provisioningProfileName" => "(MotionProvisioning) com.example.myapp #{platform} #{type}",
    "teamId" => "XXXXXXXXXX"
  }

  body["subPlatform"] = "tvOS" if platform == :tvos
  body["deviceIds"] = "DDDDDDDDDD" if type != :distribution

  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{normalized_platform.to_s}/profile/createProvisioningProfile.action").
    with(:body => body).to_return(status: 200, body: adp_read_fixture_file('create_profile_success.json').gsub('{platform}', platform.to_s), headers: { 'content-type' => 'application/json' })
end

def stub_repair_profile(type, platform)
  normalized_platform = platform == :mac ? :mac : :ios
  distribution_type = case type
                      when :distribution then "store"
                      when :development then "limited"
                      when :adhoc then "adhoc"
                      end
  certificate_type = type == :development ? :development : :distribution

  body = {
    "appIdId"=>"572XTN75U2",
    "certificateIds" => SPEC_CERTIFICATES[normalized_platform][certificate_type][:id],
    "distributionType" => distribution_type,
    "provisioningProfileId"=>"FB8594WWQG",
    "provisioningProfileName"=>"(MotionProvisioning) com.example.myapp #{platform} #{type}",
    "teamId"=>"XXXXXXXXXX"
  }

  body["deviceIds"] = "DDDDDDDDDD" if type != :distribution

  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{normalized_platform}/profile/regenProvisioningProfile.action").
    with(:body => body).to_return(status: 200, body: adp_read_fixture_file('repair_profile_success.json'), headers: { 'content-type' => 'application/json' })
end

def stub_download_profile(type, platform)
  platform_slug = platform == :mac ? 'mac' : 'ios'
  profile_content = adp_read_fixture_file("downloaded_provisioning_profile.mobileprovision")

  profile_id = 'FB8594WWQG'
  stub_request(:get, "https://developer.apple.com/services-account/QH65B2/account/#{platform_slug}/profile/downloadProfileContent?provisioningProfileId=#{profile_id}&&teamId=XXXXXXXXXX").
    to_return(status: 200, body: profile_content)

  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform_slug}/downloadProvisioningProfile.action").
    with(:body => { provisioningProfileId: profile_id, teamId: 'XXXXXXXXXX' }.to_plist).
    to_return(status: 200, body: adp_read_fixture_file("download_team_provisioning_profile.action.xml").gsub("{profile}", Base64.encode64(profile_content)), headers: { 'Content-Type' => 'text/x-xml-plist' })

  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform_slug}/downloadTeamProvisioningProfile.action").
    with(:body => { appIdId: 'L42E9BTRAB', teamId: "XXXXXXXXXX"}.to_plist).
    to_return(status: 200, body: adp_read_fixture_file("download_team_provisioning_profile.action.xml").gsub("{profile}", Base64.encode64(profile_content)), headers: { 'Content-Type' => 'text/x-xml-plist' })
end

def stub_list_existing_profiles(type, platform)
  platform_slug = platform == :mac ? 'mac' : 'ios'
  body = adp_read_fixture_file('listProvisioningProfiles.action_existing.plist').gsub("{platform}", platform.to_s)
  if platform == :tvos
    body.gsub!("<string>ios</string>", "<string>tvOS</string>")
  end
  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform_slug}/listProvisioningProfiles.action?includeInactiveProfiles=true&onlyCountLists=true&teamId=XXXXXXXXXX").
    to_return(status: 200, body: body, headers: { 'Content-Type' => 'text/x-xml-plist' })
end

def stub_list_invalid_profiles(type, platform)
  normalized_platform = platform == :mac ? :mac : :ios
  body = adp_read_fixture_file('listProvisioningProfiles.action_existing_invalid.plist').gsub("{platform}", platform.to_s)
  if platform == :tvos
    body.gsub!("<string>ios</string>", "<string>tvOS</string>")
  end
  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{normalized_platform.to_s}/listProvisioningProfiles.action?includeInactiveProfiles=true&onlyCountLists=true&teamId=XXXXXXXXXX").
    to_return(status: 200, body: body, headers: { 'Content-Type' => 'text/x-xml-plist' })
end

def stub_list_missing_profiles(type, platform)
  platform_slug = platform == :mac ? 'mac' : 'ios'
  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform_slug}/listProvisioningProfiles.action?includeInactiveProfiles=true&onlyCountLists=true&teamId=XXXXXXXXXX").
    to_return(status: 200, body: adp_read_fixture_file('listProvisioningProfiles.action.plist'), headers: { 'Content-Type' => 'text/x-xml-plist' })
end

def stub_devices
  [:ios, :mac].each do |platform|
    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/device/listDevices.action").
      with(body: { teamId: 'XXXXXXXXXX', pageSize: "500", pageNumber: "1", sort: 'name=asc' }).
      to_return(status: 200, body: adp_read_fixture_file('listDevices.action.json'), headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/device/listDevices.action").
      with(body: { deviceClasses: "tvOS", teamId: 'XXXXXXXXXX', pageSize: "500", pageNumber: "1", sort: 'name=asc' }).
      to_return(status: 200, body: adp_read_fixture_file('listDevices.action.json'), headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/listDevices.action").
      with(body: { deviceClasses: "tvOS", pageNumber: 1, pageSize: 500, sort: 'name=asc', teamId: 'XXXXXXXXXX' }.to_plist).
      to_return(status: 200, body: adp_read_fixture_file('listDevices.action.json'), headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/listDevices.action").
      with(body: { pageNumber: 1, pageSize: 500, sort: 'name=asc', teamId: 'XXXXXXXXXX' }.to_plist).
      to_return(status: 200, body: adp_read_fixture_file('listDevices.action.json'), headers: { 'Content-Type' => 'application/json' })
  end
end

def stub_existing_certificates
  [:ios, :mac].each do |platform|
    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/downloadDistributionCerts.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
      to_return(status: 200, body: adp_read_fixture_file('downloadDistributionCerts_existing.xml').gsub('{certificate}', Base64.encode64(SPEC_CERTIFICATES[platform][:distribution][:content])), headers: { 'Content-Type' => 'text/x-xml-plist' })

    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/listAllDevelopmentCerts.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
      to_return(status: 200, body: adp_read_fixture_file('listAllDevelopmentCerts_existing.xml').gsub('{certificate}', Base64.encode64(SPEC_CERTIFICATES[platform][:development][:content])), headers: { 'Content-Type' => 'text/x-xml-plist' })

stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/mac/certificate/listCertRequests.action").
         with(:body => {"pageNumber"=>"1", "pageSize"=>"500", "sort"=>"certRequestStatusCode=asc", "teamId"=>"XXXXXXXXXX", "types"=>"749Y1QAGU7,HXZEUKP0FP,2PQI8IDXNH,OYVN2GW35E,W0EURJRMC5,CDZ7EMXIZ1,HQ4KP3I34R,DIVN2GW3XT"},
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Spaceship 0.27.2'}).
         to_return(:status => 200, :body => "", :headers => {})

     stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/certificate/listCertRequests.action").
       with(:body => {"pageNumber"=>"1", "pageSize"=>"500", "sort"=>"certRequestStatusCode=asc", "teamId"=>"XXXXXXXXXX", "types"=>"5QPB9NHCEI,R58UK2EWSO,9RQEK7MSXA,LA30L5BJEU,BKLRAVXMGM,UPV3DW712I,Y3B2F3TYSI,3T2ZP62QW8,E5D663CMZW,4APLUP237T,T44PTHVNID,DZQUP8189Y,FGQUP4785Z,S5WE21TULA,3BQKVH9I2X,FUOY7LWJET"}).
       to_return(status: 200, body: adp_read_fixture_file('listCertRequests.action_existing.json').gsub("{certificate_id}", SPEC_CERTIFICATES[platform][:development][:id]).gsub("{certificate_type_id}", SPEC_CERTIFICATES[platform][:development][:type_id]), headers: { 'Content-Type' => 'application/json' })

     stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/certificate/listCertRequests.action").
       with(:body => {"pageNumber"=>"1", "pageSize"=>"500", "sort"=>"certRequestStatusCode=asc", "teamId"=>"XXXXXXXXXX", "types"=>"749Y1QAGU7,HXZEUKP0FP,2PQI8IDXNH,OYVN2GW35E,W0EURJRMC5,CDZ7EMXIZ1,HQ4KP3I34R,DIVN2GW3XT"}).
       to_return(status: 200, body: adp_read_fixture_file('listCertRequests.action_existing.json').gsub("{certificate_id}", SPEC_CERTIFICATES[platform][:development][:id]).gsub("{certificate_type_id}", SPEC_CERTIFICATES[platform][:development][:type_id]), headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/certificate/listCertRequests.action").
      with(:body => {"pageNumber"=>"1", "pageSize"=>"500", "sort"=>"certRequestStatusCode=asc", "teamId"=>"XXXXXXXXXX", "types"=>SPEC_CERTIFICATES[platform][:distribution][:type_id]}).
      to_return(status: 200, body: adp_read_fixture_file('listCertRequests.action_existing.json').gsub("{certificate_id}", SPEC_CERTIFICATES[platform][:distribution][:id]).gsub("{certificate_type_id}", SPEC_CERTIFICATES[platform][:distribution][:type_id]), headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/certificate/listCertRequests.action").
      with(:body => {"pageNumber"=>"1", "pageSize"=>"500", "sort"=>"certRequestStatusCode=asc", "teamId"=>"XXXXXXXXXX", "types"=>SPEC_CERTIFICATES[platform][:development][:type_id]}).
      to_return(status: 200, body: adp_read_fixture_file('listCertRequests.action_existing.json').gsub("{certificate_id}", SPEC_CERTIFICATES[platform][:development][:id]).gsub("{certificate_type_id}", SPEC_CERTIFICATES[platform][:development][:type_id]), headers: { 'Content-Type' => 'application/json' })
  end
end

def stub_missing_then_existing_certificates
  [:ios, :mac].each do |platform|
    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/downloadDistributionCerts.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
      to_return(status: 200, body: adp_read_fixture_file('downloadDistributionCerts_existing.xml').gsub('{certificate}', Base64.encode64(SPEC_CERTIFICATES[:ios][:distribution][:content])), headers: { 'Content-Type' => 'text/x-xml-plist' })

    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/listAllDevelopmentCerts.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
      to_return(status: 200, body: adp_read_fixture_file('listAllDevelopmentCerts_missing.xml'), headers: { 'Content-Type' => 'text/x-xml-plist' }).
      then.
      to_return(status: 200, body: adp_read_fixture_file('listAllDevelopmentCerts_existing.xml').gsub('{certificate}', Base64.encode64(SPEC_CERTIFICATES[:ios][:development][:content])), headers: { 'Content-Type' => 'text/x-xml-plist' })
  end
end

def stub_revoke_certificate(type)
  [:ios, :mac].each do |platform|
    certificate = SPEC_CERTIFICATES[platform][type]
    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/certificate/revokeCertificate.action").
      with(:body => {"certificateId"=>certificate[:id], "teamId"=>"XXXXXXXXXX", "type"=>certificate[:type_id]}).
      to_return(status: 200, body: adp_read_fixture_file('revokeCertificate.action.json'), headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/ios/revokeDevelopmentCert.action?clientId=XABBG36SBA").
      with(:body => { "serialNumber" => "EA57CB138947BCB", "teamId" => "XXXXXXXXXX" }.to_plist).
      to_return(:status => 200, :body => { "certRequests" => [] }.to_plist, :headers => {})
  end
end

def stub_download_certificate(type)
  [:ios, :mac].each do |platform|
    certificate = SPEC_CERTIFICATES[platform][type]
  stub_request(:get, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/certificate/downloadCertificateContent.action?certificateId=#{certificate[:id]}&teamId=XXXXXXXXXX&type=#{certificate[:type_id]}").
    to_return(:status => 200, :body => certificate[:content], :headers => {}).then
  end
end

def stub_missing_certificates
  [:ios, :mac].each do |platform|
    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/downloadDistributionCerts.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
      to_return(status: 200, body: adp_read_fixture_file('downloadDistributionCerts_missing.xml'), headers: { 'Content-Type' => 'text/x-xml-plist' })
    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/listAllDevelopmentCerts.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
      to_return(status: 200, body: adp_read_fixture_file('listAllDevelopmentCerts_missing.xml'), headers: { 'Content-Type' => 'text/x-xml-plist' })

    Spaceship::Portal::Certificate::CERTIFICATE_TYPE_IDS.keys.each do |type|
      stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/certificate/listCertRequests.action").
         with(:body => {"pageNumber"=>"1", "pageSize"=>"500", "sort"=>"certRequestStatusCode=asc", "teamId"=>"XXXXXXXXXX", "types"=>type}).
        to_return(status: 200, body: adp_read_fixture_file('listCertRequests.action.json'), headers: { 'Content-Type' => 'application/json' })
    end
  end
end

def stub_request_certificate(csr, type)
  # Mac cert requests are made to the ios url
  [:ios, :mac].each do |platform|
    certificate = SPEC_CERTIFICATES[platform][type]
    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform}/certificate/submitCertificateRequest.action").
      with(:body => {"appIdId"=>true, "csrContent"=>csr, "teamId"=>"XXXXXXXXXX", "type"=>certificate[:type_id]}).
      to_return(status: 200, body: adp_read_fixture_file('submitCertificateRequest.action.json').gsub("{certificate_type_id}", certificate[:type_id]).gsub("{certificate_id}", certificate[:id]), headers: { 'Content-Type' => 'application/json' })

     stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform}/submitDevelopmentCSR.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
       with(:body => { csrContent: csr, teamId: 'XXXXXXXXXX' }.to_plist).
       to_return(:status => 200, :body => adp_read_fixture_file('submitDevelopmentCSR.action.xml').gsub("{certificate_type_id}", certificate[:type_id]).gsub("{certificate_id}", certificate[:id]).gsub('{cert_content}', Base64.encode64(certificate[:content])), :headers => { 'Content-Type' => 'text/x-xml-plist' })
  end
end

def stub_missing_app
  [:ios, :mac].each do |platform|
    stub_request(:post, "https://developer.apple.com/services-account/qh65b2/account/#{platform.to_s}/identifiers/listappids.action").
      with(body: { teamid: 'xxxxxxxxxx', pagesize: "500", pagenumber: "1", sort: 'name=asc' }).
      to_return(status: 200, body: adp_read_fixture_file('listapps.action.json'), headers: { 'content-type' => 'application/json' })

    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/listAppIds.action?clientId=XABBG36SBA").
      with(body: { teamid: 'xxxxxxxxxx', pagesize: "500", pagenumber: "1", sort: 'name=asc' }.to_plist).
      to_return(status: 200, body: adp_read_fixture_file('listapps.action.json'), headers: { 'content-type' => 'text/x-xml-plist' })

    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/identifiers/addAppId.action").
      with(:body => {"appIdName"=>"My App", "appIdentifierString"=>"com.example.myapp", "explicitIdentifier"=>"com.example.myapp", "gameCenter"=>"on", "inAppPurchase"=>"on", "push"=>"on", "teamId"=>"XXXXXXXXXX", "type"=>"explicit"}).
      to_return(status: 200, body: adp_read_fixture_file('addAppId.action.explicit.json'), headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/addAppId.action?clientId=XABBG36SBA").
      with(:body => { identifier: "com.example.myapp", name: "My App", teamId: "XXXXXXXXXX" }.to_plist).
      to_return(status: 200, body: adp_read_fixture_file('addAppId.action.explicit.json'), headers: { 'Content-Type' => 'application/json' })
  end
end

def stub_existing_app
  [:ios, :mac].each do |platform|
    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/identifiers/listAppIds.action").
      with(body: { teamId: 'XXXXXXXXXX', pageSize: "500", pageNumber: "1", sort: 'name=asc' }).
      to_return(status: 200, body: adp_read_fixture_file('listApps.action_existing.json'), headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform.to_s}/listAppIds.action?clientId=XABBG36SBA").
      with(body: { teamId: 'XXXXXXXXXX', pageSize: 500, pageNumber: 1, sort: 'name=asc' }.to_plist).
      to_return(status: 200, body: adp_read_fixture_file('listApps.action_existing.xml'), headers: { 'Content-Type' => 'text/x-xml-plist' })

    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/identifiers/getAppIdDetail.action").
      with(:body => {"appIdId"=>"L42E9BTRAA", "teamId"=>"XXXXXXXXXX"}).
      to_return(status: 200, body: adp_read_fixture_file('getAppIdDetail.action.json'), headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/identifiers/getAppIdDetail.action").
      with(:body => {"appIdId"=>"L42E9BTRAB", "teamId"=>"XXXXXXXXXX"}).
      to_return(status: 200, body: adp_read_fixture_file('getAppIdDetail.action.json'), headers: { 'Content-Type' => 'application/json' })
  end
end

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.before(:each) do
    stub_login
    stub_existing_app
    stub_devices
  end
end
