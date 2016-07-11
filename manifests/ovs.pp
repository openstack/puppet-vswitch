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

class vswitch::ovs(
  $package_ensure = 'present',
  $dkms_ensure    = false,
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
        'Ubuntu': {
          # ubuntu 16.04 doesn't have upstart
          # this workaround should be removed when https://bugs.launchpad.net/ubuntu/+source/openvswitch/+bug/1585201
          # will be resolved
          if versioncmp($::operatingsystemmajrelease, '16') >= 0 {
            $ovs_status = '/etc/init.d/openvswitch-switch status | fgrep -q "not running"; if [ $? -eq 0 ]; then exit 1; else exit 0; fi'
          } else {
            $ovs_status = '/sbin/status openvswitch-switch | fgrep "start/running"'
          }
        }
        default: {
          $ovs_status = '/etc/init.d/openvswitch-switch status | fgrep -q "not running"; if [ $? -eq 0 ]; then exit 1; else exit 0; fi'
        }
      }
      service { 'openvswitch':
        ensure    => true,
        enable    => true,
        name      => $::vswitch::params::ovs_service_name,
        hasstatus => false, # the supplied command returns true even if it's not running
        status    => $ovs_status,
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
        ensure => true,
        enable => true,
        name   => $::vswitch::params::ovsdb_service_name,
        status => $::vswitch::params::ovsdb_status,
      }
      ~>
      service { 'openvswitch':
        ensure => true,
        enable => true,
        name   => $::vswitch::params::ovs_service_name,
        status => $::vswitch::params::ovs_status,
      }
    }
    'Solaris': {
      service { 'ovsdb-server':
        ensure => true,
        enable => true,
        name   => $::vswitch::params::ovsdb_service_name,
        status => $::vswitch::params::ovsdb_status,
      }
      ~>
      service { 'openvswitch':
        ensure => true,
        enable => true,
        name   => $::vswitch::params::ovs_service_name,
        status => $::vswitch::params::ovs_status,
      }
    }
    default: {
      fail( "${::osfamily} not yet supported by puppet-vswitch")
    }
  }

  package { $::vswitch::params::ovs_package_name:
    ensure => $package_ensure,
    before => Service['openvswitch'],
    tag    => 'openvswitch',
  }

  Service['openvswitch'] -> Vs_port<||>
  Service['openvswitch'] -> Vs_bridge<||>
}
