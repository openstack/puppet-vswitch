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
# [*socket_limit*]
#   (Optional) Limits the maximum amount of memory that can be used from
#   the hugepage pool, on a per-socket basis.
#   Defaults to undef.
#
# [*enable_hw_offload*]
#   (optional) Configure OVS to use
#   Hardware Offload. This feature is
#   supported from ovs 2.8.0.
#   Defaults to false.
#
# [*disable_emc*]
#   (optional) Configure OVS to disable EMC.
#   Defaults to false
#
# [*vlan_limit*]
#   (optional) Number of vlan layers allowed.
#   Default to undef
#
# [*revalidator_cores*]
#   (Optional) Number of cores to be used for OVS Revalidator threads.
#
# [*handler_cores*]
#   (Optional) Number of cores to be used for OVS handler threads.
#
# [*enable_tso*]
#   (Optional) Enable TSO support.
#   Defaults to false.
#
# [*vhost_postcopy_support*]
#   (Optional) Allow switching live migration of VM attached to
#   dpdkvhostuserclient port to post-copy mode.
#   Defaults to false
#
# [*pmd_auto_lb*]
#   (Optional) Configures PMD Auto Load Balancing
#   Defaults to false.
#
# [*pmd_auto_lb_rebal_interval*]
#   (Optional) The minimum time (in minutes) 2 consecutive PMD Auto Load
#   Balancing iterations.
#   Defaults to undef.
#
# [*pmd_auto_lb_load_threshold*]
#   (Optional) Specifies the minimum PMD thread load threshold of any
#   non-isolated PMD threads when a PMD Auto Load Balance may be triggered.
#   Defaults to undef.
#
# [*pmd_auto_lb_improvement_threshold*]
#   (Optional) Specifies the minimum evaluated % improvement in load
#   distribution across the non-isolated PMD threads that will allow a PMD Auto
#   Load Balance to occur.
#   Defaults to undef.
#
# [*vs_config*]
#   (optional) allow configuration of arbitrary vswitch configurations.
#   The value is an hash of vs_config resources. Example:
#   { 'other_config:foo' => { value => 'baa' } }
#   NOTE: that the configuration MUST NOT be already handled by this module
#   or Puppet catalog compilation will fail with duplicate resources.
#
# [*skip_restart*]
#   (optional) Skip restarting the service even when updating some options
#   which require service restart. Setting this parameter to true avoids
#   immedicate network distuption caused by restarting the ovs daemon.
#   Defaults to false.
#
class vswitch::dpdk (
  $memory_channels                   = undef,
  $host_core_list                    = undef,
  $package_ensure                    = 'present',
  $pmd_core_list                     = undef,
  $socket_mem                        = undef,
  $socket_limit                      = undef,
  $enable_hw_offload                 = false,
  $disable_emc                       = false,
  $vlan_limit                        = undef,
  $revalidator_cores                 = undef,
  $handler_cores                     = undef,
  $enable_tso                        = false,
  $vhost_postcopy_support            = false,
  $pmd_auto_lb                       = false,
  $pmd_auto_lb_rebal_interval        = undef,
  $pmd_auto_lb_load_threshold        = undef,
  $pmd_auto_lb_improvement_threshold = undef,
  $vs_config                         = {},
  $skip_restart                      = false,
) {

  include vswitch::params
  validate_legacy(Boolean, 'validate_bool', $enable_hw_offload)
  validate_legacy(Boolean, 'validate_bool', $disable_emc)
  validate_legacy(Boolean, 'validate_bool', $enable_tso)
  validate_legacy(Boolean, 'validate_bool', $vhost_postcopy_support)
  validate_legacy(Boolean, 'validate_bool', $pmd_auto_lb)
  validate_legacy(Hash, 'validate_hash', $vs_config)
  validate_legacy(Boolean, 'validate_bool', $skip_restart)

  if $vlan_limit != undef {
    validate_legacy(Integer, 'validate_integer', $vlan_limit)
  }
  if $revalidator_cores != undef {
    validate_legacy(Integer, 'validate_integer', $revalidator_cores)
  }
  if $handler_cores != undef {
    validate_legacy(Integer, 'validate_integer', $handler_cores)
  }

  $restart = !$skip_restart

  kmod::load { 'vfio-pci': }

  if $facts['os']['family'] != 'Redhat' {
    fail( "${facts['os']['family']} not yet supported for dpdk installation by puppet-vswitch")
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
    'other_config:dpdk-extra'            => { value => $memory_channels_conf, restart => $restart },
    'other_config:dpdk-socket-mem'       => { value => join(any2array($socket_mem), ','), restart => $restart},
    'other_config:dpdk-socket-limit'     => { value => join(any2array($socket_limit), ','), restart => $restart},
    'other_config:dpdk-lcore-mask'       => { value => $dpdk_lcore_mask, restart => $restart},
    'other_config:pmd-cpu-mask'          => { value => $pmd_core_mask, restart => $restart},
    'other_config:n-revalidator-threads' => { value => $revalidator_cores},
    'other_config:n-handler-threads'     => { value => $handler_cores},
  }

  $dpdk_dependencies = {
    wait   => false,
    notify => Vs_config['other_config:dpdk-init'],
  }

  if $enable_hw_offload {
    vs_config { 'other_config:hw-offload':
      value   => true,
      restart => $restart,
      wait    => true,
    }
  } else {
    vs_config { 'other_config:hw-offload':
      ensure  => absent,
      restart => $restart,
      wait    => true,
    }
  }

  if $disable_emc {
    vs_config { 'other_config:emc-insert-inv-prob':
      value => 0,
      wait  => false,
    }
  } else {
    vs_config { 'other_config:emc-insert-inv-prob':
      ensure => absent,
      wait   => false,
    }
  }

  vs_config { 'other_config:vlan-limit':
    value => $vlan_limit,
    wait  => true,
  }

  if $enable_tso {
    vs_config { 'other_config:userspace-tso-enable':
      value => true,
      wait  => false,
    }
  } else {
    vs_config { 'other_config:userspace-tso-enable':
      ensure => absent,
      wait   => false,
    }
  }

  if $vhost_postcopy_support {
    vs_config { 'other_config:vhost-postcopy-support':
      value   => true,
      restart => $restart,
      wait    => false
    }
  } else {
    vs_config { 'other_config:vhost-postcopy-support':
      ensure  => absent,
      restart => $restart,
      wait    => false
    }
  }

  if $pmd_auto_lb {
    vs_config { 'other_config:pmd-auto-lb':
      value => true,
      wait  => false,
    }

    if $pmd_auto_lb_rebal_interval {
      vs_config { 'other_config:pmd-auto-lb-rebal-interval':
        value => $pmd_auto_lb_rebal_interval,
        wait  => false;
      }
    } else {
      vs_config { 'other_config:pmd-auto-lb-rebal-interval':
        ensure => absent,
        wait   => false,
      }
    }

    if $pmd_auto_lb_load_threshold {
      vs_config { 'other_config:pmd-auto-lb-load-threshold':
        value => $pmd_auto_lb_load_threshold,
        wait  => false
      }
    } else {
      vs_config { 'other_config:pmd-auto-lb-load-threshold':
        ensure => absent,
        wait   => false
      }
    }

    if $pmd_auto_lb_improvement_threshold {
      vs_config { 'other_config:pmd-auto-lb-improvement-threshold':
        value => $pmd_auto_lb_improvement_threshold,
        wait  => false
      }
    } else {
      vs_config { 'other_config:pmd-auto-lb-improvement-threshold':
        ensure => absent,
        wait   => false
      }
    }

  } else {
    vs_config {
      'other_config:pmd-auto-lb':                       ensure => absent, wait => false;
      'other_config:pmd-auto-lb-rebal-interval':        ensure => absent, wait => false;
      'other_config:pmd-auto-lb-load-threshold':        ensure => absent, wait => false;
      'other_config:pmd-auto-lb-improvement-threshold': ensure => absent, wait => false;
    }
  }

  vs_config { 'other_config:dpdk-init':
    value   => true,
    restart => $restart,
    wait    => true,
  }

  service { 'openvswitch':
    ensure => true,
    enable => true,
    name   => $::vswitch::params::ovs_service_name,
  }

  # NOTE(tkajinam): This resource is defined to restart the openvswitch services
  # when any vs_config resource with restart => true is enabled.
  exec { 'restart openvswitch':
    path        => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
    command     => "systemctl -q restart ${::vswitch::params::ovs_service_name}.service",
    refreshonly => true,
  }

  create_resources('vs_config', $dpdk_configs, $dpdk_dependencies)
  create_resources('vs_config', $vs_config)

}
