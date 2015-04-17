# == Class: vswitch
#
# Install and configure vswitch (ovs and others) using puppet.
#
# === Parameters
#
# [*provider*]
#   Select vswitch to install
#
# === Examples
#
#  class { 'vswitch':
#    provider => 'ovs',
#  }
#
# === Authors
#
# - Endre Karlson <endre.karlson@gmail.com>
# - Dan Bode <dan@puppetlabs.com>
# - Ian Wells <iawells@cisco.com>
# - Gilles Dubreuil <gdubreui@redhat.com>
#
# === Copyright
#
# Apache License 2.0 (see LICENSE file)
#
class vswitch (
  $provider = $vswitch::params::provider
) {
  $cls = "::vswitch::${provider}"
  include $cls
}
