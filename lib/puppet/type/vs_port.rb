require "puppet"

module Puppet
    Puppet::Type.newtype(:vs_port) do
        @doc = "A Virtuak Switch"

        ensurable

        newparam(:interface) do
            isnamevar
            desc "The interface to attach to the bridge"
        end

        newparam(:bridge) do
            desc "What bridge to use"
        end
    end
end

