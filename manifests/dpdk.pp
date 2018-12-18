#
# Configure OVS to use DPDK
#
# === Parameters
#
# [*memory_channels*]
#   (optional) The number of memory channels to use as an integer.
#
# [*host_core_list*]
#   (optional) The list of cores to be used by the lcore threads.
#   The host_core_list is a string with format as <c1>[-c2][,c3[-c4],...]
#   where c1, c2, etc are core indexes between 0 and 128.
#   For example, to configure 3 cores the value should be "0-2"
#
# [*package_ensure*]
#   (Optional) State of the openvswitch package
#   Defaults to 'present'.
#
# [*pmd_core_list*]
#   (optional) The list of cores to be used by the DPDK PMD threads.
#   The pmd_core_list is a string with format as <c1>[-c2][,c3[-c4],...] where
#   c1, c2, etc are core indexes between 0 and 128
#   For example, to configure 3 cores the value should be "0-2"
#
# [*socket_mem*]
#   (Optional) Set the memory to be allocated on each socket
#   The socket_mem is a string with comma separated memory list in MB in the
#   order of socket numbers. For example, to allocate memory of 1GB for
#   socket 1 and no allocation for socket 0, the value should be "0,1024"
#   Defaults to undef.
#
# DEPRECATED PARAMETERS
#
# [*driver_type*]
#   (Optional) The DPDK Driver type
#   Defaults to 'vfio-pci'
#   This parameter is required only for OVS versions <= 2.5.
#
class vswitch::dpdk (
  $memory_channels    = undef,
  $host_core_list     = undef,
  $package_ensure     = 'present',
  $pmd_core_list      = undef,
  $socket_mem         = undef,
  # DEPRECATED PARAMETERS
  $driver_type        = 'vfio-pci',
) {

  include ::vswitch::params
  kmod::load { 'vfio-pci': }

  if $::osfamily != 'Redhat' {
    fail( "${::osfamily} not yet supported for dpdk installation by puppet-vswitch")
  }

  package { $::vswitch::params::ovs_dpdk_package_name:
    ensure => $package_ensure,
    before => Service['openvswitch'],
    tag    => 'openvswitch',
  }

  $pmd_core_mask = range_to_mask($pmd_core_list)
  $dpdk_lcore_mask = range_to_mask($host_core_list)

  if $memory_channels and !empty($memory_channels) {
    $memory_channels_conf = "-n ${memory_channels}"
  }
  else {
    $memory_channels_conf = undef
  }

  $dpdk_configs = {
    'other_config:dpdk-extra'      => { value => $memory_channels_conf},
    'other_config:dpdk-socket-mem' => { value => $socket_mem},
    'other_config:dpdk-lcore-mask' => { value => $dpdk_lcore_mask},
    'other_config:pmd-cpu-mask'    => { value => $pmd_core_mask},
  }

  $dpdk_dependencies = {
    wait    => false,
    require => Service['openvswitch'],
    notify  => Vs_config['other_config:dpdk-init'],
  }

  vs_config { 'other_config:dpdk-init':
    value   => true,
    require => Service['openvswitch'],
    wait    => true,
  }

  service { 'openvswitch':
    ensure => true,
    enable => true,
    name   => $::vswitch::params::ovs_service_name,
  }

  create_resources ('vs_config', $dpdk_configs, $dpdk_dependencies)
}
