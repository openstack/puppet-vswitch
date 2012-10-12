class vswitch::ovs {
  case $::osfamily {
    Debian: {
      package {["openvswitch-switch", "openvswitch-datapath-dkms"]:
        ensure => present,
        before => Service['openvswitch-switch'],
      }
    }
    Ubuntu: {
      package {["openvswitch-switch", "openvswitch-datapath-dkms"]:
        ensure => present,
        before => Service['openvswitch-switch'],
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
