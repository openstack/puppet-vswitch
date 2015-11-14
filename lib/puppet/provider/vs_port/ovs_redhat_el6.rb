require File.expand_path(File.join(File.dirname(__FILE__), '.','ovs_redhat.rb'))

Puppet::Type.type(:vs_port).provide(
  :ovs_redhat_el6,
  :parent => Puppet::Type.type(:vs_port).provider(:ovs_redhat)
) do
  desc 'Openvswitch port manipulation for RedHat OSes family'

  confine    :osfamily => :redhat, :operatingsystemmajrelease => 6
  defaultfor :osfamily => :redhat, :operatingsystemmajrelease => 6

  private

  def dynamic?
    # iproute doesn't behave as expected on rhel6 for dynamic interfaces
    if File.read(BASE + @resource[:interface]) =~ /^BOOTPROTO=['"]?dhcp['"]?$/
      return true
    else
      return false
    end
  end
end
