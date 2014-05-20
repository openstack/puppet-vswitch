require 'puppet'

Puppet::Type.newtype(:vs_port) do
  desc 'A Virtual Switch Port'

  ensurable

  newparam(:interface, :namevar => true) do
    desc 'The interface to attach to the bridge'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid interface #{value}. Requires a String, not a #{value.class}"
      end
    end
  end

  newparam(:bridge) do
    desc "What bridge to use"

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid bridge #{value}. Requires a String, not a #{value.class}'"
      end
    end
  end

  newparam(:keep_ip) do
    desc "True: keep physical interface's details and assign them to the bridge"

    defaultto false
  end

  newparam(:sleep) do
    desc "Waiting time, in seconds (0 by default), for network to sync after activating port, used with keep_ip only"

    defaultto '0'

    validate do |value|
      if value.to_i.class != Fixnum || value.to_i < 0
        raise ArgumentError, "sleep requires a positive integer"
      end
    end
  end

  autorequire(:vs_bridge) do
    self[:bridge] if self[:bridge]
  end
end
