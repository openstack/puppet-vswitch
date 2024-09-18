require 'puppet'

Puppet::Type.type(:vs_config).provide(:ovs) do

  commands :vsctl => 'ovs-vsctl'

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
        k,val = v.split('=', 2)
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
      if value.nil?
        next
      end
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
    # if skip_if_version matches ovs_version(), then skip the configuration by faking exists
    if @resource[:skip_if_version].eql? ovs_version()
      return true
    elsif ensure_absent?
      @property_hash[:ensure] != :present
    else
      @property_hash[:ensure] == :present
    end
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
    if @resource[:wait] == :false
      vsctl("--no-wait", "set", "Open_vSwitch", ".", "#{@resource[:name]}=#{@resource[:value]}")
    else
      vsctl("set", "Open_vSwitch", ".", "#{@resource[:name]}=#{@resource[:value]}")
    end
  end

  def create
    if ensure_absent?
      destroy
    else
      _set
    end
  end

  def value
    # if skip_if_version matches ovs_version(), then skip the configuration by returning the same value
    if @resource[:skip_if_version].eql? ovs_version()
      @resource[:value]
    elsif ensure_absent?
      @resource[:value]
    else
      @property_hash[:value]
    end
  end

  def ovs_version
    vsctl("--version")[/.*ovs-vsctl\s+\(Open\s+vSwitch\)\s+(\d+\.\d+)/][/(\d+\.\d+)/].chomp()
  end

  def value=(value)
    if ensure_absent?
      destroy
    else
      _set
    end
  end

  private

  def ensure_absent?
    (@resource[:value].nil? or @resource[:value].empty?) and @resource[:ensure] == :present
  end
end
