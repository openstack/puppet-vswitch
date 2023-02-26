# == class: vswitch::pki::cacert
#
# Initialize CA authority
#
class vswitch::pki::cacert {
  include vswitch::params

  exec { 'ovs-pki-init-ca-authority':
    command => 'ovs-pki init --force',
    creates => '/var/lib/openvswitch/pki/switchca',
    path    => ['/usr/sbin', '/sbin', '/usr/bin', '/bin'],
  }

  Package<| title == $::vswitch::params::ovs_package_name |>
    -> Exec['ovs-pki-init-ca-authority']
}
