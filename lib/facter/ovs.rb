Facter.add("ovs_version") do
  confine :kernel => "Linux"

  setcode do
    Facter::Core::Execution.exec('/usr/bin/ovs-vsctl --version').gsub(/.*ovs-vsctl\s+\(Open\s+vSwitch\)\s+(\d+\.\d+\.\d+).*/, '\1')
  end
end
