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

    def _split(string, splitter="\n")
        return Hash[string.split(splitter).map{|i| i.split("=")}]
    end

    def external_ids
        result = vsctl("br-get-external-id", @resource[:name])
        return _split result
    end

    def external_ids=(value)
        ids = _split(value, ",")
        ids.each_pair do |k,v|
            vsctl("br-set-external-id", @resource[:name], k, v)
        end
    end
end
