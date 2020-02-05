describe "Certificates" do

  [:ios, :mac].each do |platform|
    describe platform.to_s do
      [:distribution, :development_free, :development].each do |type|
        free = type == :development_free
        next if platform == :mac && free

        describe type.to_s.capitalize, platform: platform.to_s, type: type.to_s, free: free do

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

            allow($stderr).to receive(:noecho).and_yield
            allow(STDIN).to receive(:getc).and_return('1', '2', '3', "\n")
            expect(MotionProvisioning.certificate(platform: platform, type: type, free: free)).to eq(certificate[:name])
            expect(File.exist?("#{MotionProvisioning.output_path}/#{platform}_#{type}_certificate.cer")).to be true
            expect(File.exist?("#{MotionProvisioning.output_path}/#{platform}_#{type}_private_key.p12")).to be true
          end

          it "can use cached certificate that is not installed" do
            FileUtils.cp("spec/fixtures/#{platform}_#{type}_certificate.cer", MotionProvisioning.output_path)
            FileUtils.cp("spec/fixtures/#{platform}_#{type}_private_key.p12", MotionProvisioning.output_path)

            expect(MotionProvisioning.certificate(platform: platform, type: type, free: free)).to eq(certificate[:name])
          end

          it "can use cached certificate that is installed" do
            MotionProvisioning::Certificate.new.import_file("spec/fixtures/#{platform}_#{type}_certificate.cer")
            MotionProvisioning::Certificate.new.import_file("spec/fixtures/#{platform}_#{type}_private_key.p12")
            FileUtils.cp("spec/fixtures/#{platform}_#{type}_certificate.cer", MotionProvisioning.output_path)
            FileUtils.cp("spec/fixtures/#{platform}_#{type}_private_key.p12", MotionProvisioning.output_path)

            expect(MotionProvisioning.certificate(platform: platform, type: type, free: free)).to eq(certificate[:name])
          end
        end
      end
    end
  end
end
