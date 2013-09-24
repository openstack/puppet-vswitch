class vswitch (
  $provider = $vswitch::params::provider
) {
  $cls = "vswitch::$provider"
  include $cls
}
