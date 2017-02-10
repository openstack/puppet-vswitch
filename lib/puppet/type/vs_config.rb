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
        raise ArgumentError, "Invalid format for  #{value}. Requires a String with format \d+.\d+, not a #{value.class}"
      end
    end
  end

  newparam(:wait) do
    desc 'Should it wait for ovs-vswitchd to reconfigure itself before it exits'

    newvalues(:true, :false)
    defaultto :true
  end

  newproperty(:value) do
    desc 'Configuration value for the paramter'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid external_ids #{value}. Requires a String, not a #{value.class}"
      end
    end

    munge do |value|
      if value[0] == '[' && value[-1] == ']'
        "[#{value[1..-2].split(',').map(&:strip).sort.join(",")}]"
      else
        super(value)
      end
    end
  end
end

