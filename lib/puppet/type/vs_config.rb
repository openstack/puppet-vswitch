require 'puppet'

Puppet::Type.newtype(:vs_config) do
  desc 'Switch configurations'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Configuration parameter whose value need to be set'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid name #{value}. Requires a String, not a #{value.class}"
      end
    end
  end

  newparam(:skip_if_version) do
    desc 'Skip setting the value when ovs version matches'
    validate do |value|
      unless value.is_a?(String) and value =~ /^\d+.\d+$/
        raise ArgumentError, "Invalid skip_if_version #{value}. Requires a String with format \d+.\d+, not a #{value.class}"
      end
    end
  end

  newparam(:wait) do
    desc 'Should it wait for ovs-vswitchd to reconfigure itself before it exits'

    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:restart) do
    desc 'Should the openvswitch service be restarted'

    newvalues(:true, :false)
    defaultto :false
  end

  autorequire(:service) do
    ['openvswitch']
  end

  autonotify(:service) do
    ['restart openvswitch'] if self[:restart]
  end

  newproperty(:value) do
    desc 'Configuration value for the parameter'

    validate do |value|
      if !value.is_a?(String) and !value.is_a?(Integer) and !(value == true) and !(value == false)
        raise ArgumentError, "Invalid value #{value}. Requires a String, a Integer or a Boolean, not a #{value.class}"
      end
    end

    munge do |value|
      if value.is_a?(String)
        if value[0] == '[' && value[-1] == ']'
          "[#{value[1..-2].split(',').map(&:strip).sort.join(",")}]"
        else
          super(value)
        end
      else
        super(String(value))
      end
    end
  end
end

