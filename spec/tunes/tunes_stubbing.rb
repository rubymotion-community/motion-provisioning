# NOTE: All of these methods are copied directly from:
# https://github.com/fastlane/fastlane/blob/master/spaceship/spec/tunes/tunes_stubbing.rb

def itc_read_fixture_file(filename)
  File.read(File.join('spec', 'tunes', 'fixtures', filename))
end

def itc_stub_login
  # Retrieving the current login URL
  itc_service_key_path = File.expand_path("~/Library/Caches/spaceship_itc_service_key.txt")
  File.delete(itc_service_key_path) if File.exist?(itc_service_key_path)

  stub_request(:get, 'https://appstoreconnect.apple.com/itc/static-resources/controllers/login_cntrl.js').
    to_return(status: 200, body: itc_read_fixture_file('login_cntrl.js'))
  stub_request(:get, "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa").
    to_return(status: 200, body: "")
  stub_request(:get, "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/wa").
    to_return(status: 200, body: "")
  stub_request(:get, "https://appstoreconnect.apple.com/olympus/v1/session").
    to_return(status: 200, body: itc_read_fixture_file('olympus_session.json'))
  stub_request(:get, "https://appstoreconnect.apple.com/olympus/v1/app/config?hostname=itunesconnect.apple.com").
    to_return(status: 200, body: { authServiceKey: 'e0abc' }.to_json, headers: { 'Content-Type' => 'application/json' })

  # Actual login
  stub_request(:post, "https://idmsa.apple.com/appleauth/auth/signin").
    with(body: { "accountName" => "spaceship@krausefx.com", "password" => "so_secret", "rememberMe" => true }.to_json).
    to_return(status: 200, body: '{}', headers: { 'Set-Cookie' => "myacinfo=abcdef;" })

  # Failed login attempts
  stub_request(:post, "https://idmsa.apple.com/appleauth/auth/signin").
    with(body: { "accountName" => "bad-username", "password" => "bad-password", "rememberMe" => true }.to_json).
    to_return(status: 401, body: '{}', headers: { 'Set-Cookie' => 'session=invalid' })

  stub_request(:post, "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/v1/session/webSession").
    with(body: "{\"contentProviderId\":\"5678\",\"dsId\":null}",
          headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json' }).
    to_return(status: 200, body: "", headers: {})

  # 2FA: Request security code to trusted phone
  stub_request(:put, "https://idmsa.apple.com/appleauth/auth/verify/phone").
    with(body: "{\"phoneNumber\":{\"id\":1},\"mode\":\"sms\"}").
    to_return(status: 200, body: "", headers: {})

  # 2FA: Submit security code from trusted phone for verification
  stub_request(:post, "https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode").
    with(body: "{\"securityCode\":{\"code\":\"123\"},\"phoneNumber\":{\"id\":1},\"mode\":\"sms\"}").
    to_return(status: 200, body: "", headers: {})

  # 2FA: Trust computer
  stub_request(:get, "https://idmsa.apple.com/appleauth/auth/2sv/trust").
    to_return(status: 200, body: "", headers: {})
end
