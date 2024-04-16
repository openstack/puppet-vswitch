# vswitch: open-vswitch
# == Class: vswitch::ovs
#
# installs openvswitch
#
# === Parameters:
#
# [*package_name*]
#   (required) Name of OVS package.
#
# [*service_name*]
#   (required) Name of OVS service.
#
# [*package_ensure*]
#   (Optional) State of the openvswitch package
#   Defaults to 'present'.
#
# [*enable_hw_offload*]
#   (optional) Configure OVS to use
#   Hardware Offload. This feature is
#   supported from ovs 2.8.0.
#   Defaults to false.
#
# [*disable_emc*]
#   (optional) Configure OVS to disable EMC.
#   Defaults to false.
#
# [*vlan_limit*]
#   (optional) Number of vlan layers allowed.
#   Default to undef
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
class vswitch::ovs(
  String[1] $package_name,
  String[1] $service_name,
  String $package_ensure           = 'present',
  Boolean $enable_hw_offload       = false,
  Boolean $disable_emc             = false,
  Optional[Integer[0]] $vlan_limit = undef,
  Hash $vs_config                  = {},
  Boolean $skip_restart            = false,
) {

  $restart = !$skip_restart

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

  create_resources('vs_config', $vs_config)

  service { 'openvswitch':
    ensure => true,
    enable => true,
    name   => $service_name,
    tag    => 'openvswitch',
  }

  # NOTE(tkajinam): This resource is defined to restart the openvswitch service
  # when any vs_config resource with restart => true is enabled.
  exec { 'restart openvswitch':
    path        => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
    command     => ['systemctl', '-q', 'restart', "${service_name}.service"],
    refreshonly => true,
  }

  package { 'openvswitch':
    ensure => $package_ensure,
    name   => $package_name,
    before => Service['openvswitch'],
    tag    => 'openvswitch',
  }
}
