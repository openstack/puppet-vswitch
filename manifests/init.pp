# == Class: vswitch
#
# Install and configure vswitch (ovs and others) using puppet.
#
# === Parameters
#
# [*provider*]
#   Select vswitch to install
#   Defaults to 'ovs'
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
  Enum['ovs', 'dpdk'] $provider = 'ovs'
) {
  $cls = "::vswitch::${provider}"
  include $cls
}
