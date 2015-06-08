require 'spec_helper_acceptance'

describe 'basic vswitch' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      Exec { logoutput => 'on_failure' }

      case $::osfamily {
        'RedHat': {
          class { '::openstack_extras::repo::redhat::redhat':
            # Kilo is not GA yet, so let's use the testing repo
            manage_rdo => false,
            repo_hash  => {
              'rdo-kilo-testing' => {
                'baseurl'  => 'https://repos.fedorapeople.org/repos/openstack/openstack-kilo/testing/el7/',
                # packages are not GA so not signed
                'gpgcheck' => '0',
                'priority' => 97,
              },
            },
          }
        }
      }

      include ::vswitch::ovs

      vs_bridge { 'br-beaker':
        ensure => present,
      }
      EOS


      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe command('ovs-vsctl show') do
      its(:stdout) { should match /br-beaker/ }
    end
  end
end
