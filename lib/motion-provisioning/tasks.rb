require 'rake'

namespace 'motion-provisioning' do
  desc 'Add a device to the provisioning portal: rake "motion-provisioning:add-device[device_name,device_id]"'
  task 'add-device', [:name, :id] do |t, args|
    name = args[:name]
    id = args[:id]
    if name.nil? || id.nil?
      puts "Missing device name or id."
      puts "Syntax: rake \"motion-provisioning:add-device[device_name,device_id]\""
      exit
    end
    MotionProvisioning.client.create_device!(name, id)
    puts "Successfully added device (name: #{name}, id: #{id})."
  end
end
