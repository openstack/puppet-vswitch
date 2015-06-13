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
#   false. defaults to true.

class vswitch::ovs(
  $package_ensure = 'present',
  $dkms_ensure    = true,
) {

  include ::vswitch::params

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

      case $::operatingsystem {
        'ubuntu': {
          $ovs_status = '/sbin/status openvswitch-switch | fgrep "start/running"'
        }
        default: {
          $ovs_status = '/etc/init.d/openvswitch-switch status | fgrep "is running"'
        }
      }
      service { 'openvswitch':
        ensure    => true,
        enable    => true,
        name      => $::vswitch::params::ovs_service_name,
        hasstatus => false, # the supplied command returns true even if it's not running
        # Not perfect - should spot if either service is not running - but it'll do
        status    => $ovs_status
      }
    }
    'Redhat': {
      service { 'openvswitch':
        ensure => true,
        enable => true,
        name   => $::vswitch::params::ovs_service_name,
      }
    }
    'FreeBSD': {
      Package {
        provider => 'pkgng',
      }
      service { 'ovsdb-server':
        ensure => running,
        enable => true,
	name   => $::vswitch::params::ovsdb_service_name,
      }
      ~>
      service { 'openvswitch':
        ensure => running,
        enable => true,
	name   => $::vswitch::params::ovs_service_name,
      }
    }
    default: {
      fail( "${::osfamily} not yet supported by puppet-vswitch")
    }
  }

  package { $::vswitch::params::ovs_package_name:
    ensure => $package_ensure,
    before => Service['openvswitch'],
  }

  Service['openvswitch'] -> Vs_port<||>
  Service['openvswitch'] -> Vs_bridge<||>
}
