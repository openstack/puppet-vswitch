require 'spec_helper_acceptance'

describe 'basic vswitch' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      Exec { logoutput => 'on_failure' }

      case $::osfamily {
        'RedHat': {
          class { '::openstack_extras::repo::redhat::redhat':
            release => 'liberty',
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
      describe '#stdout' do
        subject { super().stdout }
        it { is_expected.to match /br-beaker/ }
      end
    end
  end
end
