require 'spec_helper_acceptance'

describe 'basic vswitch' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      include openstack_integration
      include openstack_integration::repos

      include vswitch::ovs

      vs_bridge { 'br-ci1':
        ensure => present,
      }

      vs_bridge { 'br-ci2':
        ensure       => present,
        external_ids => 'bridge-id=br-ci2'
      }

      vs_config { 'external_ids:ovn-remote':
        ensure => present,
        value  => 'tcp:127.0.0.1:2300',
      }

      vs_config { 'other_config:thisshouldexist':
        ensure => present,
        value  => 'customvalue',
      }
      vs_config { 'other_config:thisshouldnotexist':
        ensure => present,
        value  => undef,
      }
      vs_config { 'other_config:thisshouldnotexist2':
        ensure => present,
        value  => '',
      }
      vs_config { 'other_config:thisshouldnotexist3':
        ensure => present,
        value  => [],
      }
      EOS


      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should have br-ci1 bridge' do
      command('ovs-vsctl show') do |r|
        expect(r.stdout).to match(/br-ci1/)
      end
    end

    it 'should have br-ci2 bridge' do
      command('ovs-vsctl show') do |r|
        expect(r.stdout).to match(/br-ci2/)
      end
    end

    it 'should have external_ids on br-ci2 bridge' do
      command('ovs-vsctl br-get-external-id br-ci2') do |r|
        expect(r.stdout).to match(/bridge-id=br-ci2/)
      end
    end

    it 'should get remote addr' do
      command('ovs-vsctl get Open_vSwitch . external_ids:ovn-remote') do |r|
        expect(r.stdout).to match(/\"tcp:127.0.0.1:2300\"/)
      end
    end

    it 'should get other config' do
      command('sudo ovs-vsctl get Open_Vswitch . other_config') do |r|
        expect(r.stdout).to match(/\"{thishshouldexist=customvalue}"/)
      end
    end
  end
end
