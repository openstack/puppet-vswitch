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
      $provider              = 'ovs_redhat'
    }
    'Debian': {
      $ovs_package_name      = 'openvswitch-switch'
      $ovs_dpdk_package_name = 'openvswitch-switch-dpdk'
      $ovs_dkms_package_name = 'openvswitch-datapath-dkms'
      $ovs_service_name      = 'openvswitch-switch'
      $ovsdb_service_name    = undef
      $provider              = 'ovs'
      case $::operatingsystem {
        'ubuntu': {
          # ubuntu 16.04 doesn't have upstart
          # this workaround should be removed when https://bugs.launchpad.net/ubuntu/+source/openvswitch/+bug/1585201
          # will be resolved
          if versioncmp($::operatingsystemmajrelease, '16') >= 0 {
            $ovs_status = '/etc/init.d/openvswitch-switch status | fgrep -q "not running"; if [ $? -eq 0 ]; then exit 1; else exit 0; fi'
          } else {
            $ovs_status = '/sbin/status openvswitch-switch | fgrep "start/running"'
          }
          $ovs_service_hasstatus = false
        }
        'debian': {
          if ($::lsbdistcodename == 'wheezy') {
            $ovs_service_hasstatus = false
            $ovs_status            = '/etc/init.d/openvswitch-switch status | fgrep -q "not running"; if [ $? -eq 0 ]; then exit 1; else exit 0; fi' # lint:ignore:140chars
          } else {
            $ovs_service_hasstatus = true
            $ovs_status            = undef
          }
        }
        default: {
          fail('Unsupported Debian based system')
        }
      }
    }
    default: {
      fail " Osfamily ${::osfamily} not supported yet"
    }
  } # Case $::osfamily
}
