module IFCFG
  class OVS
    attr_reader :ifcfg

    def self.exists?(name)
      File.exist?(BASE + name)
    end

    def self.remove(name)
      File.delete(BASE + name)
    rescue Errno::ENOENT
    end

    def initialize(name, seed=nil)
      @name  = name
      @ifcfg = {}
      set(seed)
      set_key('DEVICE', @name)
      set_key('NAME', @name)
      set_key('DEVICETYPE', 'ovs')
      replace_key('BOOTPROTO', 'OVSBOOTPROTO') if self.class == IFCFG::Bridge
    end

    def del_key(key)
      @ifcfg.delete(key)
    end

    def key?(key)
      @ifcfg.has_key?(key)
    end

    def key(key)
      @ifcfg.has_key?(key)
    end

    def replace_key(key, new_key)
      value = @ifcfg[key]
      @ifcfg.delete(key)
      set_key(new_key, value)
    end

    def set(list)
      if list != nil && list.class == Hash
        list.each { |key, value| set_key(key, value) }
      end
    end

    def set_key(key, value)
      @ifcfg.delete_if { |k, v| k == key } if self.key?(key)
      @ifcfg.merge!({key => value })
    end

    def to_s
      str = ''
      @ifcfg.each { |x, y|
        str << "#{x}=#{y}\n"
      }
      str
    end

    def save(filename)
      File.open(filename, 'w') { |file| file << self.to_s }
    end
  end

  class Bridge < OVS
    def initialize(name, template=nil)
      super(name, template)
      set_key('TYPE', 'OVSBridge')
      del_key('HWADDR')
    end
  end

  class Port < OVS
    def initialize(name, bridge)
      super(name)
      set_key('TYPE', 'OVSPort')
      set_key('OVS_BRIDGE', bridge)
      set_key('ONBOOT', 'yes')
      set_key('BOOTPROTO', 'none')
    end
  end
end
