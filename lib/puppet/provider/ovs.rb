require 'puppet'

class Puppet::Provider::Ovs < Puppet::Provider

  initvars
  commands :vsctl => 'ovs-vsctl'

  protected

  def self.get_property(type, name, key)
    return vsctl('get', type, name, key).strip
  end

  def self.set_property(type, name, key, val=nil)
    if val.nil? or val.empty?
      vsctl('clear', type, name, key)
    else
      vsctl('set', type, name, "#{key}=#{val}")
    end
  rescue
    set_property(type, name, key, val.to_s)
  end

  def self.get_other_config(type, name, key)
    value = vsctl('get', type, name, 'other_config').strip
    value = parse_hash(value.gsub(/^{|}$/, ''))
    value[key]
  end

  def self.set_other_config(type, name, key, val=nil)
    if val.nil? or val.empty?
      vsctl('remove', type, name, 'other_config', key)
    else
      vsctl('set', type, name, "other_config:#{key}=#{val}")
    end
  rescue
    set_other_config(type, name, key, val.to_s)
  end

  def self.parse_hash(string, splitter=',')
    return Hash[string.split(splitter).map{|i| i.strip.split('=')}]
  end
end
