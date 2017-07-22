Facter.add("ovs_uuid") do
  confine :kernel => "Linux"

  setcode do
    if File.exist? '/usr/bin/ovs-vsctl'
      ovs_ver = Facter::Core::Execution.exec('/usr/bin/ovs-vsctl get Open_vSwitch . _uuid')
    end
  end
end
