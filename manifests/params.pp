class vswitch::params {
  if $::osfamily == 'Redhat' {
    $ovs_package_name = 'openvswitch'
    $ovs_service_name = 'openvswitch'
  } elsif $::osfamily == 'Debian' {
    $ovs_package_name = ['openvswitch-switch', 'openvswitch-datapath-dkms']
    $ovs_service_name = 'openvswitch-switch'
  } else {
    fail("Unsupported osfamily ${$::osfamily}")
  }
}
