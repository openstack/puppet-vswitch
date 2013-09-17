require "puppet"

Base="/etc/sysconfig/network-scripts/ifcfg-"

Puppet::Type.type(:vs_port).provide(:ovs) do
  optional_commands :vsctl => "/usr/bin/ovs-vsctl",
                    :sleep => "/bin/sleep"

  def exists?
    vsctl("list-ports", @resource[:bridge]).include? @resource[:interface]
  end

  def create
    if @resource[:keep_ip] && Facter.fact('osfamily').value == 'RedHat'
      create_bridge_file
      create_new_physical_interface_file
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
    system("ifdown #{@resource[:interface]};
      ovs-vsctl add-port #{@resource[:bridge]} #{@resource[:interface]};
      ifup #{@resource[:interface]};
      ifup #{@resource[:bridge]}")
    sleep('30')
  end 

  def create_bridge_file
    bridge_file=File.open(Base + @resource[:bridge], 'w+')
    File.open(Base + @resource[:interface]) { |file|
      file.each_line do |line|
        case line
        when /DEVICE=.*/
          bridge_file << "DEVICE=#{@resource[:bridge]}\n"
        when /TYPE=.*/
         bridge_file << "TYPE=OVSBridge\n"
        when /HWADDR=.*/
        when /UUID=.*/
        else
          bridge_file << line
        end
      end
      bridge_file << "DEVICETYPE=ovs\n"
    }
    bridge_file.close
  end  

  def create_new_physical_interface_file
    File.unlink(Base + @resource[:interface])
    file = File.open(Base + @resource[:interface], 'w+')
    file << "DEVICE=#{@resource[:interface]}\n"
    file << "DEVICETYPE=ovs\n"
    file << "TYPE=OVSPort\n"
    file << "BOOTPROTO=none\n"
    file << "OVS_BRIDGE=#{@resource[:bridge]}\n"
    file << "ONBOOT=yes\n"
    file.close
  end
end
