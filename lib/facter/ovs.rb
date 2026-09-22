Facter.add("ovs_version") do
  confine :kernel => "Linux"
  confine Facter::Core::Execution.which('ovs-vsctl')

  setcode do
    ovs_ver = Facter::Core::Execution.execute('ovs-vsctl --version')
    if ovs_ver
      ovs_ver.gsub(/.*ovs-vsctl\s+\(Open\s+vSwitch\)\s+(\d+\.\d+\.\d+).*/, '\1')
    end
  end
end
