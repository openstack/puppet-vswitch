require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppetx', 'redhat', 'ifcfg.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '.','ovs.rb'))

Puppet::Type.type(:vs_port).provide(
  :ovs_redhat,
  :parent => Puppet::Type.type(:vs_port).provider(:ovs)
) do

  BASE ||= '/etc/sysconfig/network-scripts/ifcfg-'

  # When not seedling from interface file
  DEFAULT ||= {
    'ONBOOT'        => 'yes',
    'BOOTPROTO'     => 'dhcp',
    'PEERDNS'       => 'no',
    'NM_CONTROLLED' => 'no',
    'NOZEROCONF'    => 'yes'
  }

  confine    'os.family' => :redhat
  defaultfor 'os.family' => :redhat

  commands :ip     => 'ip'
  commands :ifdown => 'ifdown'
  commands :ifup   => 'ifup'

  def initialize(value={})
    super(value)
    # Set interface property although it's not really
    # supported on this provider. This ensures that all
    # methodes inherited from the ovs provider work as
    # expected.
    @resource[:interface] = @resource[:port]
  end

  def create
    if interface_physical?
      if ! bridge.exists?
        raise Puppet::Error, "Bridge #{@resource[:bridge]} does not exist"
      end

      template = DEFAULT
      ovs_extra = get_ovs_extra(["set bridge #{@resource[:bridge]} fail_mode=#{@resource[:fail_mode]}"])

      if link?
        ovs_extra = dynamic_default if dynamic?
        if File.exist?(BASE + @resource[:port])
          template = cleared(from_str(File.read(BASE + @resource[:port])))
        end
      end

      port_cfg = IFCFG::Port.new(@resource[:port], @resource[:bridge])
      if vlan?
        port_cfg.set('VLAN' => 'yes')
      end

      if bonding?
        port_cfg.set('BONDING_MASTER' => 'yes')
        config = from_str(File.read(BASE + @resource[:port]))
        port_cfg.set('BONDING_OPTS' => config['BONDING_OPTS']) if config.has_key?('BONDING_OPTS')
      end

      port_cfg.save(BASE + @resource[:port])

      bridge_cfg = IFCFG::Bridge.new(@resource[:bridge], template)
      bridge_cfg.set(ovs_extra) if ovs_extra
      bridge_cfg.save(BASE + @resource[:bridge])

      ifdown(@resource[:bridge])
      ifdown(@resource[:port])
      ifup(@resource[:port])
      ifup(@resource[:bridge])
    else
      super
    end
  end

  def exists?
    if interface_physical?
      super &&
      IFCFG::OVS.exists?(@resource[:port]) &&
      IFCFG::OVS.exists?(@resource[:bridge])
    else
      super
    end
  end

  def destroy
    if interface_physical?
      ifdown(@resource[:bridge])
      ifdown(@resource[:port])
      IFCFG::OVS.remove(@resource[:port])
      IFCFG::OVS.remove(@resource[:bridge])
    end
    super
  end

  private

  def get_ovs_extra(opts=[])
    external_ids = bridge.external_ids
    # Add commands to set external-id
    external_ids.each do |k, v|
      opts += ["br-set-external-id #{resource[:bridge]} #{k} #{v}"]
    end

    mac_table_size = bridge.mac_table_size
    if mac_table_size
      opts += ["set bridge #{@resource[:bridge]} other-config:mac-table-size=#{mac_table_size}"]
    end

    if opts.empty?
      return {}
    else
      return { 'OVS_EXTRA' => "\"#{opts.join(' -- ')}\"" }
    end
  end

  def bonding?
    # To do: replace with iproute2 commands
    if File.exist?("/proc/net/bonding/#{@resource[:port]}")
      return true
    else
      return false
    end
  rescue Errno::ENOENT
    return false
  end

  def dynamic?
    device = ''
    device = ip('addr', 'show', @resource[:port])
    return device =~ /dynamic/ ? true : false
  end

  def link?
    if File.read("/sys/class/net/#{@resource[:port]}/operstate") =~ /up/
      return true
    else
      return false
    end
  rescue Errno::ENOENT
    return false
  end

  def dynamic_default
    list = { 'OVSDHCPINTERFACES' => @resource[:port] }
    # Persistent MAC address taken from interface
    bridge_mac_address = File.read("/sys/class/net/#{@resource[:port]}/address").chomp
    if bridge_mac_address != ''
      list.merge!(get_ovs_extra(["set bridge #{@resource[:bridge]} other-config:hwaddr=#{bridge_mac_address} fail_mode=#{@resource[:fail_mode]}"]))
    else
      list.merge!(get_ovs_extra())
    end
    list
  end

  def interface_physical?
    # OVS ports don't have entries in /sys/class/net
    # Alias interfaces (ethX:Y) must use ethX entries
    interface = @resource[:port].sub(/:\d/, '')
    ! Dir["/sys/class/net/#{interface}"].empty?
  end

  def from_str(data)
    items = {}
    data.each_line do |line|
      if m = line.match(/^([A-Za-z_]*)=(.*)$/)
        items.merge!(m[1] => m[2])
      end
    end
    items
  end

  def cleared(data)
    data.each do |key, value|
      case key
      when /vlan/i
        data.delete(key)
      when /bonding/i
        data.delete(key)
      end
    end
  end

  def vlan?
    if File.read('/proc/net/vlan/config') =~ /#{@resource[:port]}/
      return true
    else
      return false
    end
  rescue Errno::ENOENT
    return false
  end
end
