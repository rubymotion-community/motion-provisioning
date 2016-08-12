describe "Certificates" do

  [:ios, :mac].each do |platform|
    describe platform.to_s do
      [:distribution, :development_free, :development].each do |type|
        next if platform == :mac && type == :development_free

        describe type.to_s.capitalize do

          free = type == :development_free
          type = :development if type == :development_free
          let(:certificate) { SPEC_CERTIFICATES[platform][type] }

          before do
            delete_certificate(certificate[:name])
          end

          it "can create new certificate" do
            if free
              stub_missing_then_existing_certificates
            else
              stub_missing_certificates
            end
            $motion_provisioninig_csr = Spaceship.certificate.create_certificate_signing_request
            csr, pkey = $motion_provisioninig_csr
            stub_request_certificate(csr.to_s, type)
            stub_download_certificate(type)

            MotionProvisioning::Certificate.new.import_file("spec/fixtures/#{platform}_#{type}_private_key.p12")

            allow(STDIN).to receive(:gets).and_return("\n")
            expect(MotionProvisioning.certificate(platform: platform, type: type, free: free)).to eq(certificate[:name])
          end

          it "can create new certificate revoking an existing one" do
            stub_existing_certificates
            stub_revoke_certificate(type)
            $motion_provisioninig_csr = Spaceship.certificate.create_certificate_signing_request
            csr, pkey = $motion_provisioninig_csr
            stub_request_certificate(csr.to_s, type)
            stub_download_certificate(type)

            allow(STDIN).to receive(:gets).and_return('y', "\n")
            expect(MotionProvisioning.certificate(platform: platform, type: type, free: free)).to eq(certificate[:name])
          end

          it "can download a certificate that is installed locally" do
            stub_existing_certificates
            stub_download_certificate(type)

            MotionProvisioning::Certificate.new.import_file("spec/fixtures/#{platform}_#{type}_certificate.cer")
            MotionProvisioning::Certificate.new.import_file("spec/fixtures/#{platform}_#{type}_private_key.p12")

            expect(MotionProvisioning.certificate(platform: platform, type: type, free: free)).to eq(certificate[:name])
          end

          it "can use cached certificate that is not installed" do
            FileUtils.cp("spec/fixtures/#{platform}_#{type}_certificate.cer", 'provisioning/')
            FileUtils.cp("spec/fixtures/#{platform}_#{type}_private_key.p12", 'provisioning/')

            expect(MotionProvisioning.certificate(platform: platform, type: type, free: free)).to eq(certificate[:name])
          end

          it "can use cached certificate that is installed" do
            MotionProvisioning::Certificate.new.import_file("spec/fixtures/#{platform}_#{type}_certificate.cer")
            MotionProvisioning::Certificate.new.import_file("spec/fixtures/#{platform}_#{type}_private_key.p12")
            FileUtils.cp("spec/fixtures/#{platform}_#{type}_certificate.cer", 'provisioning/')
            FileUtils.cp("spec/fixtures/#{platform}_#{type}_private_key.p12", 'provisioning/')

            expect(MotionProvisioning.certificate(platform: platform, type: type, free: free)).to eq(certificate[:name])
          end
        end
      end
    end
  end
end
