describe "Application" do
  [:ios, :mac].each do |platform|
    describe platform.to_s do
      before do
        MotionProvisioning.services.clear
      end

      it "Can create a new application" do
        stub_missing_app
        MotionProvisioning.client
        MotionProvisioning::Application.find_or_create(bundle_id: "com.example.myapp", name: "My App", mac: platform == :mac)
      end

      it "can fetch existing application" do
        MotionProvisioning.client
        MotionProvisioning::Application.find_or_create(bundle_id: "com.example.myapp", name: "My App", mac: platform == :mac)
      end

      it "can enable app services" do
        stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/ios/identifiers/updateService.action").
          with(:body => {"displayId"=>"L42E9BTRAA", "featureType"=>"HK421J6T7P", "featureValue"=>"true", "teamId"=>"XXXXXXXXXX"}).
          to_return(status: 200, body: "{}", headers: { 'Content-Type' => 'application/json' })

        MotionProvisioning.services << MotionProvisioning::Service::HealthKit
        MotionProvisioning.client
        MotionProvisioning::Application.find_or_create(bundle_id: "com.example.myapp", name: "My App", mac: platform == :mac)
      end

      it "can disable app services" do
        stub_request(:post, "https://developer.apple.com/services-account/QH65B2/account/ios/identifiers/updateService.action").
          with(:body => {"displayId"=>"L42E9BTRAB", "featureType"=>"HK421J6T7P", "featureValue"=>"false", "teamId"=>"XXXXXXXXXX"}).
          to_return(status: 200, body: "{}", headers: { 'Content-Type' => 'application/json' })

        MotionProvisioning.client
        MotionProvisioning::Application.find_or_create(bundle_id: "com.example.myapp2", name: "My App", mac: platform == :mac)
      end
    end
  end
end
