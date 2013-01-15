class vswitch::ovs(
  $package_ensure = 'present'
) {
  case $::osfamily {
    Debian: {
      # OVS doesn't build unless the kernel headers are present.
      $kernelheaders_pkg = "linux-headers-$::kernelrelease" 
      if ! defined(Package[$kernelheaders_pkg]) {
        package { $kernelheaders_pkg: ensure => $package_ensure }
      }
      package {["openvswitch-switch", "openvswitch-datapath-dkms"]:
        ensure  => $package_ensure,
        before  => Service['openvswitch-switch'],
      }
      exec { 'rebuild-ovsmod':
        command => "/usr/sbin/dpkg-reconfigure openvswitch-datapath-dkms > /tmp/reconf-log",
	creates => "/lib/modules/$::kernelrelease/updates/dkms/openvswitch_mod.ko",
	require => [Package['openvswitch-datapath-dkms', $kernelheaders_pkg]],
        before  => Package['openvswitch-switch'],
      }
    }
  }

  service {"openvswitch-switch":
    ensure      => true,
    enable      => true,
    hasstatus   => false, # the supplied command returns true even if it's not running
    # Not perfect - should spot if either service is not running - but it'll do
    status      => "/etc/init.d/openvswitch-switch status | fgrep 'is running'",
  }

  Service['openvswitch-switch'] -> Vs_port<||>
  Service['openvswitch-switch'] -> Vs_bridge<||>
}
