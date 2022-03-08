# vswitch params
#
class vswitch::params {
  include openstacklib::defaults

  case $::osfamily {
    'Redhat': {
      $ovs_package_name      = 'openvswitch'
      # OVS2.5 in Red Hat family is unified package which will support plain
      # OVS and also DPDK (if enabled at runtime).
      $ovs_dpdk_package_name = 'openvswitch'
      $ovs_dkms_package_name = undef
      $ovs_service_name      = 'openvswitch'
      $ovsdb_service_name    = undef
      $ovs_service_hasstatus = undef
      $ovs_status            = undef
      $provider              = 'ovs'
    }
    'Debian': {
      $ovs_package_name      = 'openvswitch-switch'
      $ovs_dpdk_package_name = 'openvswitch-switch-dpdk'
      $ovs_dkms_package_name = 'openvswitch-datapath-dkms'
      $ovs_service_name      = 'openvswitch-switch'
      $ovsdb_service_name    = undef
      $ovs_service_hasstatus = true
      $ovs_status            = undef
      $provider              = 'ovs'
    }
    default: {
      fail " Osfamily ${::osfamily} not supported yet"
    }
  } # Case $::osfamily
}
