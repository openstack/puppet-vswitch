require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/ovs')

Puppet::Type.type(:vs_port).provide(
  :ovs,
  :parent => Puppet::Provider::Ovs
) do

  UUID_RE ||= /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/

  commands :vsctl => 'ovs-vsctl'

  has_feature :bonding
  has_feature :vlan
  has_feature :interface_type

  def exists?
    vsctl('list-ports', @resource[:bridge]).split("\n").include? @resource[:port]
  rescue Puppet::ExecutionFailure => e
    return false
  end

  def create
    if ! bridge.exists?
      raise Puppet::Error, "Bridge #{@resource[:bridge]} does not exist"
    end

    # create with first interface, other interfaces will be added later when synchronizing properties
    vsctl('--', '--id=@iface0', 'create', 'Interface', "name=#{@resource[:interface][0]}", '--', 'add-port', @resource[:bridge], @resource[:port], 'interfaces=@iface0')

    # synchronize properties
    # Only sync those properties actually supported by the provider. This
    # allows this provider to be used as a base class for providers not
    # supporting all properties.
    sync_properties = []
    if @resource.provider.class.feature?(:bonding)
      sync_properties += [:interface,
                          :bond_mode,
                          :lacp,
                          :lacp_time,
                         ]
    end
    if @resource.provider.class.feature?(:vlan)
      sync_properties += [:vlan_mode,
                          :vlan_tag,
                          :vlan_trunks,
                         ]
    end
    if @resource.provider.class.feature?(:interface_type)
      sync_properties += [:interface_type,
                         ]
    end
    for prop_name in sync_properties
      property = @resource.property(prop_name)
      property.sync unless property.safe_insync?(property.retrieve)
    end
  end

  def destroy
    vsctl('del-port', @resource[:bridge], @resource[:port])
  end

  def interface
    get_port_interface_property('name')
  end

  def interface=(value)
    # find interfaces we want to keep on the port
    keep = @resource.property(:interface).retrieve() & value
    keep_uids = keep.map { |iface| vsctl('get', 'Interface', iface, '_uuid').strip }
    new = value - keep
    args = ['--'] + new.each_with_index.map { |iface, i| ["--id=@#{i+1}", 'create', 'Interface', "name=#{iface}", '--'] }
    ifaces = (1..new.length).map { |i| "@#{i}" } + keep_uids
    args += ['set', 'Port', @resource[:port], "interfaces=#{ifaces.join(',')}"]
    vsctl(*args)
  end

  def interface_type
    types = get_port_interface_property('type').uniq
    types != nil ? types.join(' ') : :system
  end

  def interface_type=(value)
    @resource.property(:interface).retrieve.each do |iface|
      vsctl('set', 'Interface', iface, "type=#{value}")
    end
  end

  def bond_mode
    get_port_property('bond_mode')
  end

  def bond_mode=(value)
    set_port_property('bond_mode', value)
  end

  def lacp
    get_port_property('lacp')
  end

  def lacp=(value)
    set_port_property('lacp', value)
  end

  def lacp_time
    val = self.class.get_other_config('Port', @resource[:port], 'lacp-time')
    if val.nil? then '' else val.gsub(/^"|"$/, '') end
  end

  def lacp_time=(value)
    self.class.set_other_config('Port', @resource[:port], 'lacp-time', value)
  end

  def vlan_mode
    get_port_property('vlan_mode')
  end

  def vlan_mode=(value)
    set_port_property('vlan_mode', value)
  end

  def vlan_tag
    get_port_property('tag')
  end

  def vlan_tag=(value)
    set_port_property('tag', value)
  end

  def vlan_trunks
    get_port_property('trunks').scan(/\d+/)
  end

  def vlan_trunks=(value)
    set_port_property('trunks', value.join(' '))
  end

  protected

  def bridge
    @bridge ||= Puppet::Type.type(:vs_bridge).provider(:ovs).new(
      Puppet::Type::Vs_bridge.new(:title => @resource[:bridge])
    )
  end

  private

  def get_port_property(key)
    value = self.class.get_property('Port', @resource[:port], key)
    if value == '[]' then '' else value end
  end

  def set_port_property(key, value)
    self.class.set_property('Port', @resource[:port], key, value)
  end

  def get_port_interface_property(key)
    uuids = get_port_property('interfaces').scan(UUID_RE)
    uuids.map!{|id| self.class.get_property('Interface', id, key).gsub(/^"|"$/, '')}
  end
end
