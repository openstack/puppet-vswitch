require 'spec_helper_acceptance'

describe 'basic vswitch' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      include ::openstack_integration
      include ::openstack_integration::repos

      include ::vswitch::ovs

      vs_bridge { 'br-beaker':
        ensure => present,
      }

      vs_config { 'external_ids:ovn-remote':
        ensure => present,
        value => 'tcp:127.0.0.1:2300',
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

    describe command('ovs-vsctl get Open_vSwitch . external_ids:ovn-remote') do
      describe '#stdout' do
        subject { super().stdout }
        it { is_expected.to match /\"tcp:127.0.0.1:2300\"/ }
      end
    end
  end
end
