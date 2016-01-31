Facter.add("ovs_version") do
  confine :kernel => "Linux"

  setcode do
    ovs_ver = Facter::Core::Execution.exec('/usr/bin/ovs-vsctl --version')
    if ovs_ver
      ovs_ver.gsub(/.*ovs-vsctl\s+\(Open\s+vSwitch\)\s+(\d+\.\d+\.\d+).*/, '\1')
    end
  end
end
