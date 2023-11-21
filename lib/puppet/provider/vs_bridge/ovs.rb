require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/ovs')

Puppet::Type.type(:vs_bridge).provide(
  :ovs,
  :parent => Puppet::Provider::Ovs
) do
  commands :ip    => 'ip'
  commands :vsctl => 'ovs-vsctl'

  def exists?
    vsctl("br-exists", @resource[:name])
    return true
  rescue Puppet::ExecutionFailure
    return false
  end

  def create
    vsctl('add-br', @resource[:name])
    ip('link', 'set', 'dev', @resource[:name], 'up')
    if @resource[:external_ids]
      self.class.set_external_ids(@resource[:name], @resource[:external_ids])
    end
    if @resource[:mac_table_size]
      self.class.set_mac_table_size(@resource[:name], @resource[:mac_table_size])
    end
  end

  def destroy
    ip('link', 'set', 'dev', @resource[:name], 'down')
    vsctl('del-br', @resource[:name])
  end

  def external_ids
    self.class.get_external_ids(@resource[:name])
  end

  def external_ids=(value)
    self.class.set_external_ids(@resource[:name], value)
  end

  def mac_table_size
    self.class.get_mac_table_size(@resource[:name])
  end

  def mac_table_size=(value)
    self.class.set_mac_table_size(@resource[:name], value)
  end

  private

  def self.get_external_ids(br)
    value = vsctl('br-get-external-id', br)
    return parse_hash(value, "\n")
  end

  def self.set_external_ids(br, value)
    old_ids = get_external_ids(br)
    new_ids = value

    new_ids.each do |k,v|
      if !old_ids.has_key?(k) or old_ids[k] != v
        vsctl('br-set-external-id', br, k, v)
      end
    end

    old_ids.each do |k, v|
      if ! new_ids.has_key?(k)
        vsctl('br-set-external-id', br, k)
      end
    end
  end

  def self.get_mac_table_size(br)
    value = get_other_config('Bridge', br, 'mac-table-size')
    if value.nil? then nil else Integer(value.gsub(/^"|"$/, '')) end
  end

  def self.set_mac_table_size(br, value)
    set_other_config('Bridge', br, 'mac-table-size', value)
  end
end
