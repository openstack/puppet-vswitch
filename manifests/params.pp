# vswitch params
#
class vswitch::params {
  case $::osfamily {
    'Redhat': {
      $ovs_package_name = 'openvswitch'
      $ovs_service_name = 'openvswitch'
      $provider         = 'ovs_redhat'
    }
    'Debian': {
      $ovs_package_name = ['openvswitch-switch', 'openvswitch-datapath-dkms']
      $ovs_service_name = 'openvswitch-switch'
      $provider         = 'ovs'
    }
    default: {
      fail " Osfamily ${::osfamily} not supported yet"
    }
  } # Case $::osfamily
}
