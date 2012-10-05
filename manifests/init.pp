class vswitch {
    package { ["openvswitch-switch", "openvswitch-datapath-dkms"]:
        ensure => present
    }

    service { "openvswitch-switch":
        ensure      => true,
        enable      => true,
        hasstatus  => true,
        status      => "/etc/init.d/openvswitch-switch",
        require     => Package["openvswitch-switch"]
    }
}
