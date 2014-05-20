require 'puppet'

Puppet::Type.type(:vs_port).provide(:ovs) do
  desc 'Openvswitch port manipulation'

  commands :vsctl => 'ovs-vsctl'

  def exists?
    vsctl('list-ports', @resource[:bridge]).include? @resource[:interface]
  rescue Puppet::ExecutionFailure => e
    return false
  end

  def create
    vsctl('add-port', @resource[:bridge], @resource[:interface])
  end

  def destroy
    vsctl('del-port', @resource[:bridge], @resource[:interface])
  end
end
