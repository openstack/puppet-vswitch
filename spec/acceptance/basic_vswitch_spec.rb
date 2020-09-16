require 'spec_helper_acceptance'

describe 'basic vswitch' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      include openstack_integration
      include openstack_integration::repos

      include vswitch::ovs

      vs_bridge { 'br-ci':
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

    it 'should have br-ci bridge' do
      command('ovs-vsctl show') do |r|
        expect(r.stdout).to match(/br-ci/)
      end
    end

    it 'should get remote addr' do
      command('ovs-vsctl get Open_vSwitch . external_ids:ovn-remote') do |r|
        expect(r.stdout).to match(/\"tcp:127.0.0.1:2300\"/)
      end
    end
  end
end
