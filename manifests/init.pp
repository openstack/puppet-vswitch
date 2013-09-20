class vswitch (
	case $::osfamily {
    'Debian': {
    	$provider = "ovs_redhat"
    }
    'Redhat': {
    	$provider = "ovs"
    }
  }
) {
  $cls = "vswitch::$provider"
  include $cls
}
