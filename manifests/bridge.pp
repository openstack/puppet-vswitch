class vswitch::bridge (
  $ensure
) {
  vs_bridge { $br_name: 
    ensure => $ensure
  }
}
