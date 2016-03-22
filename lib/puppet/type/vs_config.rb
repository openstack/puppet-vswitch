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

