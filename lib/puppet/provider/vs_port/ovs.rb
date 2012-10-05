require "puppet"

Puppet::Type.type(:vs_port).provide(:ovs) do
    commands :vsctl => "/usr/bin/vsctl"

    def exists?
        vsctl("list-ports", @resource[:bridge]).include? @resource[:interface]
    end
end
