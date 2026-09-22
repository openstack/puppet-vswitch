Facter.add("ovs_uuid") do
  confine :kernel => "Linux"
  confine Facter::Core::Execution.which('ovs-vsctl')

  setcode do
    ovs_ver = Facter::Core::Execution.execute('ovs-vsctl get Open_vSwitch . _uuid')
  end
end
