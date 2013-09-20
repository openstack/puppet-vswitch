class vswitch::params {
  if $::osfamily == 'Redhat' {
    $ovs_package_name = 'openvswitch'
    $ovs_service_name = 'openvswitch'
    $provider         = "ovs_redhat"

  } elsif $::osfamily == 'Debian' {
    $ovs_package_name = ['openvswitch-switch', 'openvswitch-datapath-dkms']
    $ovs_service_name = 'openvswitch-switch'
    $provider         = "ovs"
  } else {
    fail("Unsupported osfamily ${$::osfamily}")
  }
}