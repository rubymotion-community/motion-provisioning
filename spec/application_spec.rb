describe "Application" do
  [:ios, :mac].each do |platform|
    describe platform.to_s, platform: platform.to_s do
      before do
        MotionProvisioning.services.clear
      end

      let(:bundle_id) { 'com.example.myapp' }
      let(:app_name) { 'My App' }

      it "Can create a new application" do
        stub_list_apps(platform, exists: false)
        stub_create_app(platform, bundle_id, app_name)
        MotionProvisioning.client
        MotionProvisioning::Application.find_or_create(bundle_id: bundle_id, name: app_name, mac: platform == :mac)
      end

      it "can fetch existing application" do
        stub_list_apps(platform, exists: true)
        MotionProvisioning.client
        MotionProvisioning::Application.find_or_create(bundle_id: bundle_id, name: app_name, mac: platform == :mac)
      end
    end
  end
end
