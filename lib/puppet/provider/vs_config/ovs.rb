require 'puppet'

Puppet::Type.type(:vs_config).provide(:ovs) do

  commands :vsctl => 'ovs-vsctl'

  mk_resource_methods

  def self.munge_array_value(value)
    "[#{value[1..-2].split(',').map(&:strip).sort.join(",")}]"
  end

  def self.parse_column_value(value)
    value = value.chomp
    if value[0] == '{'
      # hash case, like {system-id=\"some-id\", name=\"some-name\"}
      type = 'hash'
      res = {}
      value[1..-2].gsub('"','').split(', ').map(&:strip).each do |v|
        k,val = v.split("=")
        res[k] = val
      end
    elsif value[0] == '['
      # set case, like ['id1', 'id2', 'id3']
      type = 'set'
      res = munge_array_value(value)
    else
      # simple string
      type = 'string'
      res = value
    end

    {
      :type => type,
      :value => res
    }
  end

  def self.list_config_entries
    open_vs = vsctl("list", "Open_vSwitch", ".").split("\n")
    configs = []
    open_vs.each do |line|
      key, value = line.split(' : ').map(&:strip)
      parsed_value = parse_column_value(value)
      if parsed_value[:type] == "hash"
        parsed_value[:value].each do |k, v|
          configs.push({
            :name => "#{key}:#{k}",
            :value => v,
            :ensure => :present
          })
        end
      else
       configs.push({
         :name => key,
         :ensure => :present,
         :value => parsed_value[:value],
       })
      end
    end
    configs
  end

  def self.instances()
    configs = list_config_entries
    configs.collect do |config|
      new(config)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def initialize(value)
    super(value)
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    if @resource[:name].include?(':')
      name, key = @resource[:name].split(':')
      vsctl("remove", "Open_vSwitch", ".", name, key)
    else
      vsctl("clear", "Open_vSwitch", ".", @resource[:name])
    end
  end

  def _set
    vsctl("set", "Open_vSwitch", ".", "#{@resource[:name]}=#{@resource[:value]}")
  end

  def create
    _set
  end

  def value=(value)
    _set
  end
end
