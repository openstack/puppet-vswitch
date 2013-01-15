define vswitch::bridge (
  $external_ids = "",
  $ensure = "present"
) {
  if $external_ids == "" {
    vs_bridge { $name:
      ensure       => $ensure
    }
  } else {
    vs_bridge { $name:
      external_ids => $external_ids,
      ensure       => $ensure
    }
  }
}
