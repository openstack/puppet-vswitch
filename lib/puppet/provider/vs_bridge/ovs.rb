require 'puppet'

Puppet::Type.type(:vs_bridge).provide(:ovs) do
  commands :vsctl     => 'ovs-vsctl'
  if Facter.value(:operatingsystem) == 'FreeBSD'
    commands :ifconfig  => 'ifconfig'
  elsif Facter.value(:operatingsystem) == 'Solaris'
    commands :ipadm  => '/usr/sbin/ipadm'
  else
    commands :ip  => 'ip'
  end

  def exists?
    vsctl("br-exists", @resource[:name])
  rescue Puppet::ExecutionFailure
    return false
  end

  def create
    vsctl('add-br', @resource[:name])
    if Facter.value(:operatingsystem) == 'FreeBSD'
      vsctl('set','bridge',@resource[:name],'datapath_type=netdev')
      ifconfig(@resource[:name],'up')
    elsif Facter.value(:operatingsystem) == 'Solaris'
      ipadm('create-ip', @resource[:name])
    else
      ip('link', 'set', 'dev', @resource[:name], 'up')
    end
    external_ids = @resource[:external_ids] if @resource[:external_ids]
  end

  def destroy
    if Facter.value(:operatingsystem) == 'FreeBSD'
      ifconfig(@resource[:name],'down')
    else
      ip('link', 'set', 'dev', @resource[:name], 'down')
    end
    vsctl('del-br', @resource[:name])
  end

  def _split(string, splitter=',')
    return Hash[string.split(splitter).map{|i| i.split('=')}]
  end

  def external_ids
    result = vsctl('br-get-external-id', @resource[:name])
    return result.split("\n").join(',')
  end

  def external_ids=(value)
    old_ids = _split(external_ids)
    new_ids = _split(value)

    new_ids.each_pair do |k,v|
      unless old_ids.has_key?(k)
        vsctl('br-set-external-id', @resource[:name], k, v)
      end
    end
  end
end
