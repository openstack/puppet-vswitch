require 'puppet'

Puppet::Type.newtype(:vs_bridge) do
  desc 'A Switch - For example "br-int" in OpenStack'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The bridge to configure'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid name #{value}. Requires a String, not a #{value.class}"
      end
    end
  end

  newproperty(:external_ids) do
    desc 'External IDs for the bridge: "key1=value2,key2=value2"'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid external_ids #{value}. Requires a String, not a #{value.class}"
      end
      if value !~ /^(?>[a-zA-Z]\S*=\S*){1}(?>[,][a-zA-Z]\S*=\S*)*$/
        raise ArgumentError, "Invalid external_ids #{value}. Must a list of key1=value2,key2=value2"
      end
    end
  end
end
