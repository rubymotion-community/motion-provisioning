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
    end
  end
end
