require 'puppet'

Puppet::Type.newtype(:vs_port) do
  desc 'A Virtual Switch Port'

  feature :bonding, "The provider supports bonded interfaces"

  ensurable

  newparam(:port, :namevar => true) do
    desc 'Name of the port.'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid port name #{value}. Requires a String, not a #{value.class}"
      end
    end
  end

  newproperty(:interface, :array_matching => :all, :required_features => :bonding) do
    desc 'The interfaces to attach to the bridge. Defaults to the interface with the same name as the port.'

    defaultto { @resource[:port] }

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid interface #{value}. Requires a String, not a #{value.class}"
      end
    end

    # order of interfaces does not matter
    def insync?(is)
      is.sort == should.sort
    end
  end

  newparam(:bridge) do
    desc 'The bridge to attach to'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid bridge #{value}. Requires a String, not a #{value.class}'"
      end
    end
  end

  newproperty(:bond_mode, :required_features => :bonding) do
    desc "Interface bonding mode for this port.

      Possible values are 'active-backup', 'balance-tcp' or 'balance-slb'.
      By default no bonding mode is set (bond_mode='')."

    defaultto ""

    newvalues(:"active-backup", :"balance-tcp", :"balance-slb", "")
  end

  newproperty(:lacp, :required_features => :bonding) do
    desc "LACP configuration for this port.

      Possible values are 'active', 'passive' or 'off'. The default is
      'off'."

    defaultto :off

    newvalues(:active, :passive, :off)
  end

  newproperty(:lacp_time, :required_features => :bonding) do
    desc "The LACP timing which should be used on this Port.

      Possible values are 'slow' and 'fast'. The default is 'slow'.

      When configured to be fast LACP heartbeats are requested at a rate of
      once per second causing connectivity problems to be detected more quickly.
      In slow mode, heartbeats are requested at a rate of once every 30 seconds."

    # Default to the empty string which is equivalent to slow as this is also
    # the OVS default. This avoids setting a useless property on non bonded ports.
    defaultto ""

    newvalues(:fast, :slow, "")
  end

  newproperty(:vlan_mode, :required_features => :vlan) do
    desc "VLAN mode for this port.

      Possible values are 'access', 'native-tagged', 'native-untagged' or
      'trunk'. By default no mode is set (vlan_mode='')."

    defaultto ""

    newvalues(:access, :"native-tagged", :"native-untagged", :trunk, "")
  end

  newproperty(:vlan_tag, :required_features => :vlan) do
    desc "VLAN id for this port.

      For an access port this is the ports implicit VLAN id, for a for a
      'native_tagged' of 'native_untagged' port it's the ports native VLAN.
      By default no VLAN id is assigned (vlan_tag='')."

    defaultto ""

    munge do |value|
      case value
      when ""
        ""
      when String
        value.to_i
      else
        value
      end
    end

    validate do |value|
      if value.to_s != "" and (value.to_s !~ /^\d+$/ or value.to_i < 1 or value.to_i > 4094)
        raise ArgumentError, "'%s' is not a valid VLAN id. VLAN ids must be a number between 1 and 4094." % value
      end
    end
  end

  newproperty(:vlan_trunks, :array_matching => :all, :required_features => :vlan) do
    desc "Allowed VLAN ids on this port.

      This parameter is only meaningful for no access ports. Ports in native-tagged or
      native-untagged mode allways allow their native VLAN id.

      VLAN ids may be specified as a list of integers. Defaults to []."

    defaultto []

    validate do |value|
      begin
        value = Integer(value)
      rescue ArgumentError
        raise ArgumentError, "VLAN ids must be integers and '#{value}' can't be converted to an Integer"
      end
      if value < 1 or value > 4094
        raise ArgumentError, "'#{value}' is not a valid VLAN id. VLAN ids must be a number between 1 and 4094."
      end
    end

    # order of VLAN ids is not important
    def insync?(is)
      is.sort == should.sort
    end

    # avoid different formatting for 'is' value than for 'should'
    def is_to_s(value)
      value.join(" ")
    end
  end

  autorequire(:vs_bridge) do
    self[:bridge] if self[:bridge]
  end
end
