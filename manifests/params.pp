# vswitch params
#
class vswitch::params {
  include openstacklib::defaults

  case $facts['os']['family'] {
    'Redhat': {
      $ovs_package_name      = 'openvswitch'
      # OVS2.5 in Red Hat family is unified package which will support plain
      # OVS and also DPDK (if enabled at runtime).
      $ovs_dpdk_package_name = 'openvswitch'
      $ovs_service_name      = 'openvswitch'
      $provider              = 'ovs'
    }
    'Debian': {
      $ovs_package_name      = 'openvswitch-switch'
      $ovs_dpdk_package_name = 'openvswitch-switch-dpdk'
      $ovs_service_name      = 'openvswitch-switch'
      $provider              = 'ovs'
    }
    default: {
      fail " Osfamily ${facts['os']['family']} not supported yet"
    }
  } # Case $facts['os']['family']
}
