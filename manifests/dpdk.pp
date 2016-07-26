#
# Configure OVS to use DPDK
#
# === Parameters
#
# [*core_list*]
#   (required) The list of cores to be used by the DPDK Poll Mode Driver
#   The core_list is a string with format as <c1>[-c2][,c3[-c4],...] where c1, c2, etc are core indexes between 0 and 128
#   For example, to configure 3 cores the value should be "0-2"
#
# [*memory_channels*]
#   (required) The number of memory channels to use as an integer
#
# [*package_ensure*]
#   (Optional) State of the openvswitch package
#   Defaults to 'present'.
#
# [*socket_mem*]
#   (Optional) Set the memory to be allocated on each socket
#   The socket_mem is a string with comma separated memory list in MB in the order of socket numbers.
#   For example, to allocate memory of 1GB for socket 1 and no allocation for socket 0, the value should be "0,1024"
#   Defaults to undef.
#
# [*driver_type*]
#   (Optional) The DPDK Driver type
#   Defaults to 'vfio-pci'
#
class vswitch::dpdk (
  $core_list,
  $memory_channels,
  $package_ensure     = 'present',
  $socket_mem         = undef,
  $driver_type        = 'vfio-pci',
) {

  include ::vswitch::params

  kmod::load { 'vfio-pci': }

  package { $::vswitch::params::ovs_dpdk_package_name:
    ensure => $package_ensure,
    before => Service['openvswitch'],
    tag    => 'openvswitch',
  }

  # Set DPDK_OPTIONS to openvswitch
  if $socket_mem {
    $socket_string = "--socket-mem ${socket_mem}"
  }

  if $driver_type {
    $pci_list = inline_template('<%= Facter.value("pci_address_driver_#@driver_type") %>')
    unless empty($pci_list) {
      $white_list = inline_template('-w <%= @pci_list.gsub(",", " -w ") %>')
    }
  }

  $options = "DPDK_OPTIONS = \"-l ${core_list} -n ${memory_channels} ${socket_string} ${white_list}\""

  case $::osfamily {
    'Redhat': {
      file_line { '/etc/sysconfig/openvswitch':
        path    => '/etc/sysconfig/openvswitch',
        match   => '^DPDK_OPTIONS.*',
        line    => $options,
        require => Package[$::vswitch::params::ovs_dpdk_package_name],
        before  => Service['openvswitch']
      }

      service { 'openvswitch':
        ensure => true,
        enable => true,
        name   => $::vswitch::params::ovs_service_name,
      }
    }
    default: {
      fail( "${::osfamily} not yet supported for dpdk installation by puppet-vswitch")
    }
  }

}
