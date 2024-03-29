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

    munge do |value|
      return value if value.is_a? Hash

      internal = Hash.new
      value.split(",").map{|el| el.strip()}.each do |pair|
        key, value = pair.split("=", 2)
        internal[key.strip()] = value.strip()
      end
      return internal
    end

    validate do |value|
      if value.is_a?(Hash)
        true
      elsif value.is_a?(String)
        if value !~ /^(?>[a-zA-Z]\S*=\S*){1}(?>[,][a-zA-Z]\S*=\S*)*$/
          raise ArgumentError, "Invalid external_ids #{value}. Must a list of key1=value2,key2=value2"
        end
      else
        raise ArgumentError, "Invalid external_ids #{value}. Requires a String or a Hash, not a #{value.class}"
      end
    end
  end

  newproperty(:mac_table_size) do
    desc 'Mac table size'
    validate do |value|
      if !value.is_a?(Integer)
        raise ArgumentError, "Invalid mac_table_size #{value}. Requires an Integer, not a #{value.class}"
      end
    end
  end

  autorequire(:service) do
    ['openvswitch']
  end
end
