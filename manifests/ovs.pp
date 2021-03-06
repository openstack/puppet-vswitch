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
# [*dkms_ensure*]
#   (optional) on debian/wheezy, ubuntu/precise, ubuntu/trusty and
#   ubuntu/utopic dkms (Dynamic Kernel Module Support) is used to
#   have a kernel module which matches the running kernel.
#   In newer distributions (which ship with a newer kernel) dkms
#   is not available anymore for openvswitch.
#   For RedHat this parameter is ignored.
#   If you like turn off dkms on Debian/Ubuntu set to
#   false. defaults to false.
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
#   Default to $::os_service_default
#
# [*vs_config*]
#   (optional) allow configuration of arbitary vsiwtch configurations.
#   The value is an hash of vs_config resources. Example:
#   { 'other_config:foo' => { value => 'baa' } }
#   NOTE: that the configuration MUST NOT be already handled by this module
#   or Puppet catalog compilation will fail with duplicate resources.
#
class vswitch::ovs(
  $package_ensure    = 'present',
  $dkms_ensure       = false,
  $enable_hw_offload = false,
  $disable_emc       = false,
  $vlan_limit        = $::os_service_default,
  $vs_config         = {},
) {

  include vswitch::params
  validate_legacy(Hash, 'validate_hash', $vs_config)

  case $::osfamily {
    'Debian': {
      if $dkms_ensure {
        package { $::vswitch::params::ovs_dkms_package_name:
          ensure  => $package_ensure,
        }
        # OVS doesn't build unless the kernel headers are present.
        $kernelheaders_pkg = "linux-headers-${::kernelrelease}"
        if ! defined(Package[$kernelheaders_pkg]) {
          package { $kernelheaders_pkg: ensure => $package_ensure }
        }
        exec { 'rebuild-ovsmod':
          command     => '/usr/sbin/dpkg-reconfigure openvswitch-datapath-dkms > /tmp/reconf-log',
          creates     => "/lib/modules/${::kernelrelease}/updates/dkms/openvswitch_mod.ko",
          require     => [Package[$::vswitch::params::ovs_dkms_package_name , $kernelheaders_pkg]],
          before      => Package['openvswitch-switch'],
          refreshonly => true,
        }
      }

      if $::ovs_version {
        $major_version = regsubst($::ovs_version, '^(\d+).*', '\1')
        if $major_version == '1' {
          $kernel_mod_file = "/lib/modules/${::kernelrelease}/updates/dkms/openvswitch_mod.ko"
        } else {
          $kernel_mod_file = "/lib/modules/${::kernelrelease}/updates/dkms/openvswitch.ko"
        }
      }

    }
    default: {
      # to appease the lint gods.
    }
  }

  # lint:ignore:quoted_booleans
  if $enable_hw_offload {
    vs_config { 'other_config:hw-offload':
      value  => 'true',
      notify => Service['openvswitch'],
      wait   => true,
    }
  }
  # lint:endignore

  if $disable_emc {
    vs_config { 'other_config:emc-insert-inv-prob':
      value => '0',
      wait  => false,
    }
  }

  if ! is_service_default($vlan_limit) {
    vs_config { 'other_config:vlan-limit':
      value => "${vlan_limit}",
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

  package { $::vswitch::params::ovs_package_name:
    ensure => $package_ensure,
    before => Service['openvswitch'],
    tag    => 'openvswitch',
  }

  Service['openvswitch'] -> Vs_port<||>
  Service['openvswitch'] -> Vs_bridge<||>
}
