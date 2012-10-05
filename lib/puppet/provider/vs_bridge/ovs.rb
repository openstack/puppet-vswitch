require "puppet"

Puppet::Type.type(:vs_bridge).provide(:ovs) do
    commands :vsctl => "/usr/bin/ovs-vsctl"

    def exists?
        vsctl("br-exists", @resource[:name])
    rescue Puppet::ExecutionFailure
        return false
    end

    def create
        vsctl("add-br", @resource[:name])
    end

    def destroy
        vsctl("del-br", @resource[:name])
    end
end
