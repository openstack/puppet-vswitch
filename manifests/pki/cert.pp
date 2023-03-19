# == define: vswitch::pki::cert
#
# Generate certificate
#
# == Parameters:
#
# [*cert_dir*]
#  (Optional) The directory in which the cert files are generated.
#  Defaults to '/etc/openvswitch'
#
define vswitch::pki::cert(
  Stdlib::Absolutepath $cert_dir = '/etc/openvswitch',
) {
  include vswitch::params

  exec { "ovs-req-and-sign-cert-${name}":
    command => "ovs-pki req+sign ${name}",
    cwd     => $cert_dir,
    creates => "${cert_dir}/${name}-cert.pem",
    path    => ['/usr/sbin', '/sbin', '/usr/bin', '/bin'],
  }

  Package<| title == $::vswitch::params::ovs_package_name |>
    -> Exec["ovs-req-and-sign-cert-${name}"]

  Exec<| title == 'ovs-pki-init-ca-authority' |>
    -> Exec["ovs-req-and-sign-cert-${name}"]
}
