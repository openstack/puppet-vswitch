define vswitch::port (
  $bridge,
  $ensure = present
) {
  vs_port { $name:
    bridge   => $bridge,
    ensure   => $ensure
  }
}
