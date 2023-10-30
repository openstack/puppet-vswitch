#
# Configure OVS to use DPDK
#
# === Parameters
#
# [*package_name*]
#   (required) Name of OVS DPDK package.
#
# [*service_name*]
#   (required) Name of OVS service with DPDK functionality.
#
# [*package_ensure*]
#   (Optional) State of the openvswitch package
#   Defaults to 'present'.
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
  String[1] $package_name,
  String[1] $service_name,
  String $package_ensure                                                          = 'present',
  Optional[Variant[Integer[0], String]] $memory_channels                          = undef,
  Optional[String] $host_core_list                                                = undef,
  Optional[String] $pmd_core_list                                                 = undef,
  Optional[Variant[String, Integer, Array[String], Array[Integer]]] $socket_mem   = undef,
  Optional[Variant[String, Integer, Array[String], Array[Integer]]] $socket_limit = undef,
  Boolean $enable_hw_offload                                                      = false,
  Boolean $disable_emc                                                            = false,
  Optional[Integer[0]] $vlan_limit                                                = undef,
  Optional[Integer[0]] $revalidator_cores                                         = undef,
  Optional[Integer[0]] $handler_cores                                             = undef,
  Boolean $enable_tso                                                             = false,
  Boolean $vhost_postcopy_support                                                 = false,
  Boolean $pmd_auto_lb                                                            = false,
  Optional[Integer[0]] $pmd_auto_lb_rebal_interval                                = undef,
  Optional[Integer[0]] $pmd_auto_lb_load_threshold                                = undef,
  Optional[Integer[0]] $pmd_auto_lb_improvement_threshold                         = undef,
  Hash $vs_config                                                                 = {},
  Boolean $skip_restart                                                           = false,
) {

  $restart = !$skip_restart

  kmod::load { 'vfio-pci': }

  package { 'openvswitch':
    ensure => $package_ensure,
    name   => $package_name,
    before => Service['openvswitch'],
    tag    => 'openvswitch',
  }

  $pmd_core_mask = range_to_mask($pmd_core_list)
  $dpdk_lcore_mask = range_to_mask($host_core_list)

  if $memory_channels =~ String {
    warning('Support for string by memory_channels is deprecated. Use integer instead')
  }
  $memory_channels_conf = $memory_channels ? {
    String  => empty($memory_channels) ? {
      true    => undef,
      default => "-n ${memory_channels}",
    },
    Integer => "-n ${memory_channels}",
    default => undef,
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
    name   => $service_name,
    tag    => 'openvswitch',
  }

  # NOTE(tkajinam): This resource is defined to restart the openvswitch services
  # when any vs_config resource with restart => true is enabled.
  exec { 'restart openvswitch':
    path        => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
    command     => "systemctl -q restart ${service_name}.service",
    refreshonly => true,
  }

  create_resources('vs_config', $dpdk_configs, $dpdk_dependencies)
  create_resources('vs_config', $vs_config)

}
