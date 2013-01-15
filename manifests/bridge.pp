class vswitch::bridge (
  $name,
  $external_ids = "",
  $ensure = "present"
) {
  if $external_ids == "" {
    vs_bridge { $name:
      ensure       => $ensure
    } <- Class['vswitch']
  } else {
    vs_bridge { $name:
      external_ids => $external_ids,
      ensure       => $ensure
    } <- Class['vswitch']
  }
}
