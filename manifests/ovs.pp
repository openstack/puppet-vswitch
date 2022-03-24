# vswitch: open-vswitch
# == Class: vswitch::ovs
#
# installs openvswitch
#
# === Parameters:
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
#   (optional) allow configuration of arbitary vsiwtch configurations.
#   The value is an hash of vs_config resources. Example:
#   { 'other_config:foo' => { value => 'baa' } }
#   NOTE: that the configuration MUST NOT be already handled by this module
#   or Puppet catalog compilation will fail with duplicate resources.
#
# DEPRECATED PARAMETERS
#
# [*dkms_ensure*]
#   (optional) on debian/wheezy, ubuntu/precise, ubuntu/trusty and
#   ubuntu/utopic dkms (Dynamic Kernel Module Support) is used to
#   have a kernel module which matches the running kernel.
#   In newer distributions (which ship with a newer kernel) dkms
#   is not available anymore for openvswitch.
#   For RedHat this parameter is ignored.
#   If you like turn off dkms on Debian/Ubuntu set to false.
#   defaults to undef.
#
class vswitch::ovs(
  $package_ensure    = 'present',
  $enable_hw_offload = false,
  $disable_emc       = false,
  $vlan_limit        = undef,
  $vs_config         = {},
  $dkms_ensure       = undef,
) {

  include vswitch::params
  validate_legacy(Hash, 'validate_hash', $vs_config)

  if $dkms_ensure {
    warning('The dkms_ensure parameter is deprecated and has no effect')
  }

  if $enable_hw_offload {
    vs_config { 'other_config:hw-offload':
      value   => true,
      restart => true,
      wait    => true,
    }
  } else {
    vs_config { 'other_config:hw-offload':
      ensure  => absent,
      restart => true,
      wait    => true,
    }
  }
  # lint:endignore

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

  if is_service_default($vlan_limit) {
    warning('Usage of $::os_service_default for vlan_limit is deprecated. Use undef instead')
    vs_config { 'other_config:vlan-limit':
      ensure => absent,
      wait   => true,
    }
  } else {
    vs_config { 'other_config:vlan-limit':
      value => $vlan_limit,
      wait  => true,
    }
  }

  create_resources('vs_config', $vs_config)

  service { 'openvswitch':
    ensure    => true,
    enable    => true,
    name      => $::vswitch::params::ovs_service_name,
    status    => $::vswitch::params::ovs_status,
    hasstatus => $::vswitch::params::ovs_service_hasstatus
  }

  if $::vswitch::params::ovsdb_service_name {
    service { 'ovsdb-server':
      ensure => true,
      enable => true,
      name   => $::vswitch::params::ovsdb_service_name,
      status => $::vswitch::params::ovsdb_status,
    }

    Service['ovsdb-server'] ~> Service['openvswitch']
  }

  # NOTE(tkajinam): This resource is defined to restart the openvswitch service
  # when any vs_config resource with restart => true is enabled.
  exec { 'restart openvswitch':
    path        => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
    command     => "systemctl -q restart ${::vswitch::params::ovs_service_name}.service",
    refreshonly => true,
  }

  package { $::vswitch::params::ovs_package_name:
    ensure => $package_ensure,
    before => Service['openvswitch'],
    tag    => 'openvswitch',
  }

  Service['openvswitch'] -> Vs_port<||>
  Service['openvswitch'] -> Vs_bridge<||>
  Service['openvswitch'] -> Vs_config<||>
}
