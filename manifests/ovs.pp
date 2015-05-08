# vswitch: open-vswitch
#
# [*package_ensure*]
#   (Optional) State of the openvswitch package
#   Defaults to 'present'.
#
class vswitch::ovs(
  $package_ensure = 'present'
) {

  include ::vswitch::params

  case $::osfamily {
    'Debian': {
      # OVS doesn't build unless the kernel headers are present.
      $kernelheaders_pkg = "linux-headers-${::kernelrelease}"
      if ! defined(Package[$kernelheaders_pkg]) {
        package { $kernelheaders_pkg: ensure => $package_ensure }
      }
      case $::operatingsystem {
        'ubuntu': {
          $ovs_status = '/sbin/status openvswitch-switch | fgrep "start/running"'
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

      $major_version = regsubst($::ovs_version, '^(\d+).*', '\1')
      if $major_version == '1' {
        $kernel_mod_file = "/lib/modules/${::kernelrelease}/updates/dkms/openvswitch_mod.ko"
      } else {
        $kernel_mod_file = "/lib/modules/${::kernelrelease}/updates/dkms/openvswitch.ko"
      }


      exec { 'rebuild-ovsmod':
        command     => '/usr/sbin/dpkg-reconfigure openvswitch-datapath-dkms > /tmp/reconf-log',
        creates     => $kernel_mod_file,
        require     => [Package['openvswitch-datapath-dkms', $kernelheaders_pkg]],
        before      => Package['openvswitch-switch'],
      }
    }
    'Redhat': {
      service { 'openvswitch':
        ensure => true,
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
