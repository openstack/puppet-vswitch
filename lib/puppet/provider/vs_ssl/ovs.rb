Puppet::Type.type(:vs_ssl).provide(:ovs) do
  commands :vsctl => 'ovs-vsctl'

  bootstrap_ca_cert = '/etc/openvswitch/cacert.pem'

  def singleton_check
    if not @resource[:name].eql? 'system'
      raise Puppet::Error, "OVS ssl provider only supports singleton instance with name 'system'"
    end
  end

  def parse_ssl_output(filter=false)
    output = vsctl('get=ssl').split("\n")
    if output.empty?
      return false
    end

    if filter == false
      return output
    end

    output.each do |line|
      key, value = line.split(': ').map(&:strip)
      if key.eql? filter
        return value
      end
    end

    raise Puppet::Error, "Unable to parse ssl output for filter: #{filter} in ssl output: #{output}"
  end

  def create
    singleton_check
    unless File.file?(@resource[:key_file])
      raise Puppet::Error, "Key file not found: #{@resource[:key_file]}"
    end
    unless File.file?(@resource[:cert_file])
      raise Puppet::Error, "Certificate file not found: #{@resource[:cert_file]}"
    end
    if @resource[:bootstrap]
      vsctl('--', '--bootstrap', 'set-ssl', @resource[:key_file], @resource[:cert_file], bootstrap_ca_cert)
    else
      unless File.file?(@resource[:ca_file])
        raise Puppet::Error, "CA Certificate file not found: #{@resource[:ca_file]}"
      end
      vsctl('--', 'set-ssl', @resource[:key_file], @resource[:cert_file], @resource[:ca_file])
    end
  end

  def destroy
    vsctl('del-ssl')
  end

  def exists?
    singleton_check
    output = vsctl('get-ssl')
    if output.empty?
      return false
    else
      return true
    end
  end

  def key_file
    return parse_ssl_output('Private key')
  end

  def key_file=(key_file)
    destroy
    create
  end

  def cert_file
    return parse_ssl_output('Certificate')
  end

  def cert_file=(cert_file)
    destroy
    create
  end

  def ca_file
    return parse_ssl_output('CA Certificate')
  end

  def ca_file=(ca_file)
    destroy
    create
  end

  def bootstrap
    return parse_ssl_output('Bootstrap')
  end

  def bootstrap=(bootstrap)
    destroy
    create
  end

end
