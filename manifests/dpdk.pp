#
# Configure OVS to use DPDK
#
# === Parameters
#
# [*memory_channels*]
#   (required) The number of memory channels to use as an integer
#
# [*driver_type*]
#   (Optional) The DPDK Driver type
#   Defaults to 'vfio-pci'
#
# [*host_core_list*]
#   (optional) The list of host cores to be used by the DPDK Poll Mode Driver
#   The host_core_list is a string with format as <c1>[-c2][,c3[-c4],...] where c1, c2, etc are core indexes between 0 and 128
#   For example, to configure 3 cores the value should be "0-2"
#
# [*package_ensure*]
#   (Optional) State of the openvswitch package
#   Defaults to 'present'.
#
# [*pmd_core_list*]
#   (optional) The list of cores to be used by the OVS Agent
#   The pmd_core_list is a string with format as <c1>[-c2][,c3[-c4],...] where c1, c2, etc are core indexes between 0 and 128
#   For example, to configure 3 cores the value should be "0-2"
#
# [*socket_mem*]
#   (Optional) Set the memory to be allocated on each socket
#   The socket_mem is a string with comma separated memory list in MB in the order of socket numbers.
#   For example, to allocate memory of 1GB for socket 1 and no allocation for socket 0, the value should be "0,1024"
#   Defaults to undef.
#
# DEPRECATED PARAMETERS
#
# [*core_list*]
#   (optional) Deprecated.
#   The list of cores to be used by the DPDK Poll Mode Driver
#   The core_list is a string with format as <c1>[-c2][,c3[-c4],...] where c1, c2, etc are core indexes between 0 and 128
#   For example, to configure 3 cores the value should be "0-2"
#   Defaults to undef.
#
class vswitch::dpdk (
  $memory_channels,
  $driver_type        = 'vfio-pci',
  $host_core_list     = undef,
  $package_ensure     = 'present',
  $pmd_core_list      = undef,
  $socket_mem         = undef,
  # DEPRECATED PARAMETERS
  $core_list          = undef,
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
  if $host_core_list {
    $core_list_string = $host_core_list
  }
  elsif $core_list {
    warning('core_list is deprecated, will be used when host_core_list is not defined and will be removed in a future release.')
    $core_list_string = $core_list
  }
  else {
    fail('host_core_list must be set for ovs agent when DPDK is enabled')
  }
  $options = "DPDK_OPTIONS = \"-l ${core_list_string} -n ${memory_channels} ${socket_string} ${white_list}\""
  if $pmd_core_list {
    $pmd_core_list_updated = inline_template('<%= @pmd_core_list.split(",").map{|c| c.include?("-")?(c.split("-").map(&:to_i)[0]..c.split("-").map(&:to_i)[1]).to_a.join(","):c}.join(",") %>')
    $pmd_core_mask = inline_template('<%= @pmd_core_list_updated.split(",").map{|c| 1<<c.to_i}.inject(0,:|).to_s(16)  %>')
    vs_config { 'other_config:pmd-cpu-mask':
      value   => $pmd_core_mask,
      require => Service['openvswitch'],
    }
  }
  case $::osfamily {
    'Redhat': {
      file_line { '/etc/sysconfig/openvswitch':
        path    => '/etc/sysconfig/openvswitch',
        match   => '^DPDK_OPTIONS.*',
        line    => $options,
        require => Package[$::vswitch::params::ovs_dpdk_package_name],
        before  => Service['openvswitch'],
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
