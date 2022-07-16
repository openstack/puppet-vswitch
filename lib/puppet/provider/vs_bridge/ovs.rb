require 'puppet'

Puppet::Type.type(:vs_bridge).provide(:ovs) do
  commands :vsctl => 'ovs-vsctl'
  commands :ip    => 'ip'

  def exists?
    vsctl("br-exists", @resource[:name])
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

  def self._split(string, splitter=',')
    return Hash[string.split(splitter).map{|i| i.split('=')}]
  end

  def external_ids
    self.class.get_external_ids(@resource[:name])
  end

  def external_ids=(value)
    self.class.set_external_ids(@resource[:name], value)
  end

  def self.get_external_ids(br)
    result = vsctl('br-get-external-id', br)
    return result.split("\n").join(',')
  end

  def self.set_external_ids(br, value)
    old_ids = _split(get_external_ids(br))
    new_ids = _split(value)

    new_ids.each_pair do |k,v|
      unless old_ids.has_key?(k)
        vsctl('br-set-external-id', br, k, v)
      end
    end
  end

  def mac_table_size
    self.class.get_mac_table_size(@resource[:name])
  end

  def mac_table_size=(value)
    self.class.set_mac_table_size(@resource[:name], value)
  end

  def self.get_mac_table_size(br)
    value = get_bridge_other_config(br)['mac-table-size']
    if value
      Integer(value.gsub(/^"|"$/, ''))
    else
      nil
    end
  end

  def self.set_mac_table_size(br, value)
    vsctl('set', 'Bridge', br, "other-config:mac-table-size=#{value}")
  end

  private

  def self.get_bridge_other_config(br)
    value = vsctl('get', 'Bridge', br, 'other-config').strip
    value = value.gsub(/^{|}$/, '').split(',').map{|i| i.strip}
    return Hash[value.map{|i| i.split('=')}]
  end
end
