require_relative 'portal/portal_stubbing'
require_relative 'tunes/tunes_stubbing'

def stub_login
  itc_stub_login # authentication
  adp_stub_login # list paid teams

  # List free teams
  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/listTeams.action").
     to_return(status: 200, body: adp_read_fixture_file('listTeams.action.json'), headers: { 'Content-Type' => 'application/json' })
end

def stub_devices
  adp_stub_devices # only stubs iOS/tvOS requests

  # Mac
  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/mac/device/listDevices.action").
    with(body: { includeRemovedDevices:"false", pageNumber:"1", pageSize:"500", sort:"name=asc", teamId:"XXXXXXXXXX"}).
    to_return(status: 200, body: adp_read_fixture_file('listDevices.action.json'), headers: { 'Content-Type' => 'application/json' })
end

def stub_list_apps(platform, exists: true)
  normalized_platform = platform == :mac ? :mac : :ios
  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{normalized_platform}/identifiers/listAppIds.action").
    with(body: { teamId: 'XXXXXXXXXX', pageSize: "500", pageNumber: "1", sort: 'name=asc' }).
    to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: adp_read_fixture_file(exists ? 'listApps.action_existing.json' : 'listApps.action_empty.json'),
    )

  if platform == :mac
    # NOTE: for some reason, Mac also requests list of iOS apps
    stub_list_apps(:ios, exists: exists)
  end
end

def stub_create_app(platform, bundle_id, app_name)
  # NOTE: app in response body is hard-coded as ios
  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform}/identifiers/addAppId.action").
    with(body: { "identifier" => bundle_id, "name" => app_name, "gameCenter" => "on", "inAppPurchase" => "on", "teamId" => "XXXXXXXXXX", "type" => "explicit" }).
    to_return(status: 200, body: adp_read_fixture_file('addAppId.action.explicit.json'), headers: { 'Content-Type' => 'application/json' })
end

def stub_list_certificates(platform, type, exists: true)
  # adp_stub_certificates # can't use this because we need to change the response values

  normalized_platform = platform == :mac ? :mac : :ios
  certificate_type = type == :development ? :development : :distribution

  request_body = {
    "pageNumber" => "1",
    "pageSize" => "500",
    "sort" => "certRequestStatusCode=asc",
    "teamId" => "XXXXXXXXXX",
    "types" => case normalized_platform
      when :ios
        "83Q87W3TGH,WXV89964HE,5QPB9NHCEI,R58UK2EWSO,9RQEK7MSXA,LA30L5BJEU,BKLRAVXMGM,UPV3DW712I,Y3B2F3TYSI,3T2ZP62QW8,E5D663CMZW,4APLUP237T,MD8Q2VRT6A,T44PTHVNID,DZQUP8189Y,FGQUP4785Z,S5WE21TULA,3BQKVH9I2X,FUOY7LWJET"
      when :mac
        "83Q87W3TGH,WXV89964HE,749Y1QAGU7,HXZEUKP0FP,2PQI8IDXNH,OYVN2GW35E,W0EURJRMC5,CDZ7EMXIZ1,HQ4KP3I34R,DIVN2GW3XT"
      end
  }

  if exists
    response_body = adp_read_fixture_file('listCertRequests.action_existing.json').
                      gsub("{certificate_id}", SPEC_CERTIFICATES[platform][certificate_type][:id]).
                      gsub("{certificate_type_id}", SPEC_CERTIFICATES[platform][certificate_type][:type_id])
  else
    response_body = adp_read_fixture_file('listCertRequests.action_empty.json')
  end

  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{normalized_platform}/certificate/listCertRequests.action").
    with(body: request_body).
    to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{normalized_platform}/certificate/listCertRequests.action").
    with(body: { "pageNumber" => "1", "pageSize" => "500", "sort" => "certRequestStatusCode=asc", "teamId" => "XXXXXXXXXX", "types" => SPEC_CERTIFICATES[platform][certificate_type][:type_id]}).
    to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

  if exists
    # Requests for additional details about certificates use developerservices2 domain
    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{normalized_platform}/downloadDistributionCerts.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
      to_return(status: 200, body: adp_read_fixture_file('downloadDistributionCerts_existing.xml').gsub('{certificate}', Base64.encode64(SPEC_CERTIFICATES[platform][:distribution][:content])), headers: { 'Content-Type' => 'text/x-xml-plist' })

    stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{normalized_platform}/listAllDevelopmentCerts.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
      to_return(status: 200, body: adp_read_fixture_file('listAllDevelopmentCerts_existing.xml').gsub('{certificate}', Base64.encode64(SPEC_CERTIFICATES[platform][:development][:content])), headers: { 'Content-Type' => 'text/x-xml-plist' })
  end

  if platform == :mac
    # NOTE: for some reason, Mac also requests list of iOS certificates
    stub_list_certificates(:ios, type, exists: exists)
  end
end

# Only used for free development team
def stub_missing_then_existing_certificates(platform)
  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform}/certificate/listCertRequests.action").
    with(:body => {"pageNumber"=>"1", "pageSize"=>"500", "sort"=>"certRequestStatusCode=asc", "teamId"=>"XXXXXXXXXX", "types"=>"83Q87W3TGH,WXV89964HE,5QPB9NHCEI,R58UK2EWSO,9RQEK7MSXA,LA30L5BJEU,BKLRAVXMGM,UPV3DW712I,Y3B2F3TYSI,3T2ZP62QW8,E5D663CMZW,4APLUP237T,MD8Q2VRT6A,T44PTHVNID,DZQUP8189Y,FGQUP4785Z,S5WE21TULA,3BQKVH9I2X,FUOY7LWJET"}).
    to_return(status: 200, body: adp_read_fixture_file('listCertRequests.action_existing.json').gsub("{certificate_id}", SPEC_CERTIFICATES[platform][:development][:id]).gsub("{certificate_type_id}", SPEC_CERTIFICATES[platform][:development][:type_id]), headers: { 'Content-Type' => 'application/json' })

  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform}/listAllDevelopmentCerts.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
    to_return(status: 200, body: adp_read_fixture_file('listAllDevelopmentCerts_missing.xml'), headers: { 'Content-Type' => 'text/x-xml-plist' }).
    then.
    to_return(status: 200, body: adp_read_fixture_file('listAllDevelopmentCerts_existing.xml').gsub('{certificate}', Base64.encode64(SPEC_CERTIFICATES[:ios][:development][:content])), headers: { 'Content-Type' => 'text/x-xml-plist' })
end

def stub_revoke_certificate(platform, type)
  certificate = SPEC_CERTIFICATES[platform][type]
  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/certificate/revokeCertificate.action").
    with(:body => {"certificateId"=>certificate[:id], "teamId"=>"XXXXXXXXXX", "type"=>certificate[:type_id]}).
    to_return(status: 200, body: adp_read_fixture_file('revokeCertificate.action.json'), headers: { 'Content-Type' => 'application/json' })

  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/ios/revokeDevelopmentCert.action?clientId=XABBG36SBA").
    with(:body => { "serialNumber" => "EA57CB138947BCB", "teamId" => "XXXXXXXXXX" }.to_plist).
    to_return(:status => 200, :body => { "certRequests" => [] }.to_plist, :headers => {})
end

def stub_download_certificate(platform, type)
  certificate = SPEC_CERTIFICATES[platform][type]
  stub_request(:get, "https://developer.apple.com/services-account/QH65B2/account/#{platform.to_s}/certificate/downloadCertificateContent.action?certificateId=#{certificate[:id]}&teamId=XXXXXXXXXX&type=#{certificate[:type_id]}").
    to_return(:status => 200, :body => certificate[:content], :headers => {})
end

def stub_create_certificate(platform, type, csr)
  certificate = SPEC_CERTIFICATES[platform][type]
  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{platform}/certificate/submitCertificateRequest.action").
    with(body: {"appIdId"=>nil, "csrContent"=>csr, "specialIdentifierDisplayId"=>nil, "teamId"=>"XXXXXXXXXX", "type"=>certificate[:type_id]}).
    to_return(status: 200, body: adp_read_fixture_file('submitCertificateRequest.action.json').gsub("{certificate_type_id}", certificate[:type_id]).gsub("{certificate_id}", certificate[:id]), headers: { 'Content-Type' => 'application/json' })
end

def stub_create_free_certificate(platform, type, csr)
  certificate = SPEC_CERTIFICATES[platform][type]
  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{platform}/submitDevelopmentCSR.action?clientId=XABBG36SBA&teamId=XXXXXXXXXX").
    with(:body => { csrContent: csr, teamId: 'XXXXXXXXXX' }.to_plist).
    to_return(:status => 200, :body => adp_read_fixture_file('submitDevelopmentCSR.action.xml').gsub("{certificate_type_id}", certificate[:type_id]).gsub("{certificate_id}", certificate[:id]).gsub('{cert_content}', Base64.encode64(certificate[:content])), :headers => { 'Content-Type' => 'text/x-xml-plist' })
end

def stub_list_profiles(platform, type, exists: true, invalid: false)
  normalized_platform = platform == :mac ? :mac : :ios

  # NOTE: developerservices2 request is used for fetching additional information about profile
  if invalid
    filename = 'listProvisioningProfiles.action_existing_invalid.plist'
  elsif exists
    filename = 'listProvisioningProfiles.action_existing.plist'
  else
    filename = 'listProvisioningProfiles.action_empty.plist'
  end
  body = adp_read_fixture_file(filename).gsub("{platform}", platform.to_s)
  if platform == :tvos
    body.gsub!("{subPlatform}", "tvOS")
    body.gsub!("<string>ios</string>", "<string>tvOS</string>")
  else
    body.gsub!("{subPlatform}", '')
  end
  stub_request(:post, "https://developerservices2.apple.com/services/QH65B2/#{normalized_platform}/listProvisioningProfiles.action?includeExpiredProfiles=true&includeInactiveProfiles=true&onlyCountLists=true&teamId=XXXXXXXXXX").
    to_return(status: 200, body: body, headers: { 'Content-Type' => 'text/x-xml-plist' })
end

def stub_create_profile(platform, type)
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

  if platform == :tvos
    body["subPlatform"] = "tvOS"
    body["deviceIds"] = "EEEEEEEEEE" if type != :distribution
  else
    body["deviceIds"] = "DDDDDDDDDD" if type != :distribution
  end

  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{normalized_platform}/profile/createProvisioningProfile.action").
    with(:body => body).
    to_return(status: 200, body: adp_read_fixture_file('createProvisioningProfile.action_success.json').gsub('{platform}', platform.to_s), headers: { 'content-type' => 'application/json' })
end

def stub_repair_profile(platform, type)
  normalized_platform = platform == :mac ? :mac : :ios
  distribution_type = case type
                      when :distribution then "store"
                      when :development then "limited"
                      when :adhoc then "store"
                      end
  certificate_type = type == :development ? :development : :distribution

  # NOTE: for some reason, even mac makes this ios request
  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/ios/profile/listProvisioningProfiles.action").
    with(body: { "pageNumber"=>"1", "pageSize"=>"1", "sort"=>"name=asc", "teamId"=>"XXXXXXXXXX" }).
    to_return(status: 200, body: adp_read_fixture_file('listProvisioningProfiles.action_existing.json'), headers: {})

  body = {
    "appIdId"=>"572XTN75U2",
    "certificateIds" => SPEC_CERTIFICATES[normalized_platform][certificate_type][:id],
    "distributionType" => distribution_type,
    "provisioningProfileId"=>"FB8594WWQG",
    "provisioningProfileName"=>"(MotionProvisioning) com.example.myapp #{platform} #{type}",
    "teamId"=>"XXXXXXXXXX"
  }
  if platform == :tvos
    body["subPlatform"] = "tvOS"
    body["deviceIds"] = "EEEEEEEEEE" if type != :distribution
  else
    body["deviceIds"] = "DDDDDDDDDD" if type != :distribution
  end
  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{normalized_platform}/profile/regenProvisioningProfile.action").
    with(:body => body).
      to_return(status: 200, body: adp_read_fixture_file('regenProvisioningProfile.action_success.json'), headers: { 'content-type' => 'application/json' })
end

def stub_download_profile(platform, type)
  normalized_platform = platform == :mac ? :mac : :ios
  certificate_type = type == :development ? :development : :distribution
  certificate = SPEC_CERTIFICATES[normalized_platform][certificate_type]
  profile_id = 'FB8594WWQG'

  profile_content = adp_read_fixture_file("downloadProfileContent.mobileprovision")
  stub_request(:get, "https://developer.apple.com/services-account/QH65B2/account/#{normalized_platform}/profile/downloadProfileContent?provisioningProfileId=#{profile_id}&&teamId=XXXXXXXXXX").
    to_return(status: 200, body: profile_content)

  response_body = adp_read_fixture_file('getProvisioningProfile.action.json').gsub("{certificate_id}", certificate[:id])
  stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/#{normalized_platform}/profile/getProvisioningProfile.action").
    with(:body => {"provisioningProfileId"=>profile_id, "teamId"=>"XXXXXXXXXX"}).
    to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
end
