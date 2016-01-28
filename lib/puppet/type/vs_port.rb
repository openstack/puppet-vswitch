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

  autorequire(:vs_bridge) do
    self[:bridge] if self[:bridge]
  end
end
