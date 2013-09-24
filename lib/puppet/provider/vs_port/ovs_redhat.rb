require "puppet"

Puppet::Type.type(:vs_port).provide(:ovs_redhat) do
  desc "Openvswitch port manipulation for RedHat family OSs"

  confine :osfamily => :redhat
  defaultfor :osfamily => :redhat

  optional_commands :vsctl => "/usr/bin/ovs-vsctl",
                    :sleep => "/bin/sleep"

  def exists?
    vsctl("list-ports", @resource[:bridge]).include? @resource[:interface]
  end

  def create
    if @resource[:keep_ip]
      create_bridge_file
      create_physical_interface_file
      activate_port
    else
      vsctl("add-port", @resource[:bridge], @resource[:interface])
    end
  end

  def destroy
    vsctl("del-port", @resource[:bridge], @resource[:interface])
  end

  private

  def activate_port
    atomic_operation="ifdown #{@resource[:interface]};
      ovs-vsctl add-port #{@resource[:bridge]} #{@resource[:interface]};
      ifup #{@resource[:interface]};
      ifup #{@resource[:bridge]}"
    system(atomic_operation)
    sleep(@resource[:sleep]) if @resource[:sleep]
  end 

  def create_physical_interface_file
    file = File.open(Base + @resource[:interface], 'w+')
    file << "DEVICE=#{@resource[:interface]}\n"
    file << "DEVICETYPE=ovs\n"
    file << "TYPE=OVSPort\n"
    file << "BOOTPROTO=none\n"
    file << "OVS_BRIDGE=#{@resource[:bridge]}\n"
    file << "ONBOOT=yes\n"
    file.close
  end

  def search(file_name, value)
    File.open(file_name) { |file| 
      file.each_line { |line| 
        match = value.match(line)
        return match[0] if match
      }
    }
  end

  def create_bridge_file
    bridge_file = File.open(Base + @resource[:bridge], 'w+')
    interface_file_name = Base + @resource[:interface]

    # Ultimately this to go to vs_bridge
    bridge_file << "DEVICE=#{@resource[:bridge]}\n"
    bridge_file << "TYPE=OVSBridge\n"
    bridge_file << "DEVICETYPE=ovs\n"
    bridge_file << "ONBOOT=yes\n"
    # End ultimately

    case search(interface_file_name, /bootproto=.*/i)
    when /dhcp/
       bridge_file << "OVSBOOTPROTO=dhcp\n"
       bridge_file << "OVSDHCPINTERFACES=#{@resource[:interface]}\n"
    when /static/, /none/
      bridge_file << "OVSBOOTPROTO=static\n"  

      ipaddr = search(interface_file_name, /ipaddr=.*/i)
      if ipaddr.class == String
        bridge_file << ipaddr + "\n"
      else
        raise RuntimeError, 'Undefined IP address'
      end
      
      mask = search(interface_file_name, /(prefix|netmask)=.*/i)
      if mask.class == String
        bridge_file << mask + "\n"
      else
        raise RuntimeError, 'Undefined netmask or prefix'
      end
    else 
      raise RuntimeError, 'Undefined boot protocol'
    end
 
    # The idea here to have a fixed MAC address
    datapath_id = vsctl("get", "bridge", @resource[:bridge], 'datapath_id')
    bridge_mac_address = datapath_id[-14..-3].scan(/.{1,2}/).join(':') if datapath_id
 
    if bridge_mac_address
      bridge_file << "OVS_EXTRA=\"set bridge #{@resource[:bridge]} other-config:hwaddr=#{bridge_mac_address}\"\n"
    end
    bridge_file.close
  end
end