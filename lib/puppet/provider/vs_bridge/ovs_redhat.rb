require "puppet"

Base="/etc/sysconfig/network-scripts/ifcfg-" 

Puppet::Type.type(:vs_bridge).provide(:ovs) do
  desc "Openvswitch bridge manipulation for RedHat family OSs"

  confine :osfamily => :redhat
  defaultfor :osfamily => :redhat

  optional_commands :vsctl => "/usr/bin/ovs-vsctl",
                    :ip    => "/sbin/ip"

  def exists?
    vsctl("br-exists", @resource[:name])
  rescue Puppet::ExecutionFailure
    return false
  end

  def create
    vsctl("add-br", @resource[:name])
    set_resiliency
    ip("link", "set", @resource[:name], "up")
    external_ids = @resource[:external_ids] if @resource[:external_ids]
  end

  def destroy
    vsctl("del-br", @resource[:name])
  end

  private

  def set_resiliency
   # datapath_id = vsctl("get bridge #{@resource[:name]}", "datapath_id")
   # bridge_mac_address = datapath_id[-12..-1].scan(/.{1,2}/).join(':') if datapath_id
    
    File.open(Base + @resource[:bridge], 'w+') { |bridge_file| 
      bridge_file << "DEVICE=#{@resource[:bridge]}\n"
      bridge_file << "TYPE=OVSBridge\n"
      bridge_file << "DEVICETYPE=ovs\n" 
   #   if bridge_mac_address
   #     bridge_file << "OVS_EXTRA=\"set bridge #{@resource[:name]} other-config:hwaddr=#{bridge_mac_address}\"\n"
   #   end
    }
  end  

  def _split(string, splitter=",")
    return Hash[string.split(splitter).map{|i| i.split("=")}]
  end

  def external_ids
    result = vsctl("br-get-external-id", @resource[:name])
    return result.split("\n").join(",")
  end

  def external_ids=(value)
    old_ids = _split(external_ids)
    new_ids = _split(value)

    new_ids.each_pair do |k,v|
      unless old_ids.has_key?(k)
        vsctl("br-set-external-id", @resource[:name], k, v)
      end
    end
  end
end
