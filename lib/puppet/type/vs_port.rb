require "puppet"

module Puppet
  Puppet::Type.newtype(:vs_port) do
    @doc = "A Virtual Switch Port"

    ensurable

    newparam(:interface) do
      isnamevar
      desc "The interface to attach to the bridge"
    end

    newparam(:bridge) do
      desc "What bridge to use"
    end

    # newparam(:keep_ip, :boolean => true, :parent => Puppet::Parameter::Boolean) do
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
        else
          super
        end
      end
    end
    
    autorequire(:vs_bridge) do
      [self[:bridge]]
    end

  end
end

