require 'fileutils'
require 'yaml'
require 'base64'
require 'date'

require 'plist'
require 'security'
require 'highline/import'
require 'spaceship'
require 'motion-provisioning/spaceship/portal/certificate'
require 'motion-provisioning/spaceship/portal_client'
require 'motion-provisioning/spaceship/free_portal_client'

require 'motion-provisioning/utils'
require 'motion-provisioning/tasks'
require 'motion-provisioning/version'
require 'motion-provisioning/certificate'
require 'motion-provisioning/application'
require 'motion-provisioning/mobileprovision'
require 'motion-provisioning/provisioning_profile'

module MotionProvisioning

  class << self
    attr_accessor :free, :team
  end

  def self.client
    Spaceship::Portal.client ||= begin

      FileUtils.mkdir_p(MotionProvisioning.output_path)

      if File.exist?('.gitignore') && File.read('.gitignore').match(/^provisioning$/).nil?
        answer = Utils.ask("Info", "Do you want to add the 'provisioning' folder fo your '.gitignore' file? (Recommended) (Y/n):")
        `echo provisioning >> .gitignore` if answer.yes?
      end

      client = if free
        Spaceship::FreePortalClient.new
      else
        Spaceship::PortalClient.new
      end

      email = ENV['MOTION_PROVISIONING_EMAIL'] || MotionProvisioning.config['email'] || Utils.ask("Info", "Your Apple ID email:").answer

      config_path = File.join(MotionProvisioning.output_path, 'config.yaml')

      if ENV['MOTION_PROVISIONING_EMAIL'].nil? && !File.exist?(config_path)
        answer = Utils.ask("Info", "Do you want to save the email to the config file ('#{MotionProvisioning.output_path}/config.yaml') so you dont have to type it again? (Y/n):")
        if answer.yes?
          File.write(config_path, { 'email' => email }.to_yaml)
        end
      end

      password = ENV['MOTION_PROVISIONING_PASSWORD']

      server_name = "motionprovisioning.#{email}"
      item = Security::InternetPassword.find(server: server_name)
      password ||= item.password if item

      if password.nil?
        Utils.log("Info", "The login information you enter will be stored safely in the macOS keychain.")
        password = Utils.ask_password("Info", "Password for #{email}:")
        Security::InternetPassword.add(server_name, email, password)
      end

      Utils.log("Info", "Logging into the Developer Portal with email '#{email}'.")
      begin
        client.user = email
        client.send_shared_login_request(email, password)
      rescue Spaceship::Client::InvalidUserCredentialsError => ex
        Utils.log("Error", "There was an error logging into your account. Your password may be wrong.")

        if Utils.ask("Info", 'Do you want to reenter your password? (Y/n):').yes?

          # The 'delete' method is very verbose, temporarily disable output
          orig_stdout = $stdout.dup
          $stdout.reopen('/dev/null', 'w')
          Security::InternetPassword.delete(server: server_name)
          $stdout.reopen(orig_stdout)

          password = Utils.ask_password("Info", "Password for #{email}:")
          Security::InternetPassword.add(server_name, email, password)
          retry
        else
          abort
        end
      end

      if self.free
        client.teams.each do |team|
          if team['currentTeamMember']['roles'].include?('XCODE_FREE_USER')
            client.team_id = team['teamId']
            self.team = team
          end
        end

        if client.team_id.nil?
          raise "The current user does not belong to a free team."
        end
      else
        if team_id = MotionProvisioning.config['team_id'] || ENV['MOTION_PROVISIONING_TEAM_ID']
          found = false
          client.teams.each do |team|
            if team_id == team['teamId']
              client.team_id = team_id
              self.team = team
              found = true
            end
          end

          if found == false
            raise "The current user does not belong to team with ID '#{team_id}' selected in config.yml."
          end
        else
          team_id = client.select_team
          self.team = client.teams.detect { |team| team['teamId'] == team_id }
        end
      end

      Utils.log("Info", "Selected team \"#{team['name']}\" (#{team['teamId']}).")
      if File.exist?(config_path) && ENV['MOTION_PROVISIONING_TEAM_ID'].nil? && MotionProvisioning.config['team_id'].nil?
        answer = Utils.ask("Info", "Do you want to save the team \"#{team['name']}\" (#{team['teamId']}) in the config file ('#{MotionProvisioning.output_path}/config.yaml') so you dont have to select it again? (Y/n):")
        if answer.yes?
          config = YAML.load(File.read(config_path))
          config['team_id'] = team['teamId']
          File.write(config_path, config.to_yaml)
        end
      end

      Spaceship::App.set_client(client)
      Spaceship::AppGroup.set_client(client)
      Spaceship::Device.set_client(client)
      Spaceship::Certificate.set_client(client)
      Spaceship::ProvisioningProfile.set_client(client)

      client
    end
  end

  def self.config
    return @config if @config
    config_path = File.join(MotionProvisioning.output_path, 'config.yaml')
    if File.exist?(config_path)
      @config = YAML.load(File.read(config_path)) || {}
    else
      @config = {}
    end
  end

  def self.output_path=(path)
    path = File.expand_path(path)
    Utils.log('Info', "Output directory for MotionProvisioning set to '#{path}'.")
    @output_path = path
  end

  def self.output_path
    @output_path ||= File.expand_path('provisioning')
  end

  def self.services
    @services ||= []
  end

  def self.services=(services)
    @services = services
  end

  def self.entitlements
    self.services.map(&:to_hash).inject({}, &:merge!)
  end

  def self.certificate(opts = {})
    unless opts[:platform]
      Utils.log("Error", "Certificate 'platform' is required")
      exit(1)
    end

    unless opts[:type]
      Utils.log("Error", "Certificate 'type' is required")
      exit(1)
    end

    if opts[:free] == true && opts[:type] != :development
      Utils.log("Error", "You can only create a 'free' certificate for type 'development'. You selected type '#{opts[:type].to_s}'")
      exit(1)
    end

    opts[:platform] = :ios if opts[:platform] == :tvos

    supported_platforms = [:ios, :mac]
    unless supported_platforms.include?(opts[:platform])
      Utils.log("Error", "Invalid value'#{opts[:platform]}'for 'platorm'. Supported values: #{supported_platforms}")
      exit(1)
    end

    supported_types = [:distribution, :development, :developer_id]
    unless supported_types.include?(opts[:type])
      Utils.log("Error", "Invalid value '#{opts[:type]}'for 'type'. Supported values: #{supported_types}")
      exit(1)
    end

    MotionProvisioning.free = opts[:free]
    Certificate.new.certificate_name(opts[:type], opts[:platform])
  end

  def self.profile(opts = {})
    unless opts[:bundle_identifier]
      Utils.log("Error", "'bundle_identifier' is required")
      exit(1)
    end

    unless opts[:app_name]
      Utils.log("Error", "'app_name' is required")
      exit(1)
    end

    supported_platforms = [:ios, :tvos, :mac]
    unless supported_platforms.include?(opts[:platform])
      Utils.log("Error", "Invalid value'#{opts[:platform]}'for 'platorm'. Supported values: #{supported_platforms}")
      exit(1)
    end

    supported_types = [:distribution, :adhoc, :development]
    unless supported_types.include?(opts[:type])
      Utils.log("Error", "Invalid value '#{opts[:type]}'for 'type'. Supported values: #{supported_types}")
      exit(1)
    end

    if opts[:free] == true && opts[:type] != :development
      Utils.log("Error", "You can only create a 'free' provisioning profile for type 'development'. You selected type '#{opts[:type].to_s}'")
      exit(1)
    end

    MotionProvisioning.free = opts[:free]
    ProvisioningProfile.new.provisioning_profile(opts[:bundle_identifier], opts[:app_name], opts[:platform], opts[:type])
  end

end
