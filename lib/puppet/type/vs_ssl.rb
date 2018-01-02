Puppet::Type.newtype(:vs_ssl) do

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of SSL configuration"
    newvalues(/^\w+$/)
  end

  newparam(:key_file) do
    desc "Private key file path"
    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Key file path must be a string"
      end
    end
  end

  newparam(:cert_file) do
    desc "Certificate filepath"
    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Certificate file path must be a string"
      end
    end
  end

  newparam(:ca_file) do
    desc "CA authority certificate file path"
    validate do |value|
      if value
        if !value.is_a?(String)
          raise ArgumentError, "CA cert file path must be a string"
        end
      end
    end
  end

  newparam(:bootstrap, :boolean => true) do
    desc "Enable bootstrapping without CA certificate and accept controller CA cert"
    defaultto false
  end
end
