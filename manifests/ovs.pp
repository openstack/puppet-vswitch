class vswitch::ovs {
  case $::osfamily {
    Debian: {
      package {["openvswitch-switch", "openvswitch-datapath-dkms"]: ensure => present}

      service { 'ovsdb-server':
        name      => $::quantum::params::ovs_service,
        enable    => true,
        ensure    => running,
        hasstatus => false,
        status    => 'pgrep ovsdb-server',
        require   => Package['openvswitch-datapath-dkms'],
      }
    }
    Ubuntu: {
      package {["openvswitch-switch", "openvswitch-datapath-dkms"]: ensure => present}

      service {"openvswitch-switch":
        ensure      => true,
        enable      => true,
        hasstatus   => true,
        status      => "/etc/init.d/openvswitch-switch",
      }
    }
  }
}
