class vswitch::ovs(
  $package_ensure = 'present'
) {
  case $::osfamily {
    Debian: {
      ensure_resource(
        'package',
        'linux-headers-3.2.0-23-generic',
        {'ensure' => 'present' }
      )
      package {["openvswitch-switch", "openvswitch-datapath-dkms"]:
        ensure  => $package_ensure,
        require => Package['linux-headers-3.2.0-23-generic'],
        before  => Service['openvswitch-switch'],
      }
    }
  }

  service {"openvswitch-switch":
    ensure      => true,
    enable      => true,
    hasstatus   => true,
    status      => "/etc/init.d/openvswitch-switch status",
  }
}
