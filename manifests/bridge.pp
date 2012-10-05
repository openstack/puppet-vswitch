class vswitch::bridge (
  $br_name,
  $ensure
) {
  vs_bridge { $br_name: 
    ensure => $ensure
  }
}
