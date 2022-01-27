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

      vs_bridge { 'br-ci3':
        ensure       => present,
        external_ids => 'bridge-id=br-ci3'
      }
      ~> exec { 'create_loop1_port':
        path        => '/usr/bin:/bin:/usr/sbin:/sbin',
        provider    => shell,
        command     => 'ip link add name loop1 type dummy && ip addr add 127.2.0.1/24 dev loop1',
        before      => Vs_port['loop1'],
        refreshonly => true,
      }
      -> vs_port { 'loop1':
        ensure => present,
        bridge => 'br-ci3',
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

    it 'should have br-ci3 bridge' do
      command('ovs-vsctl show') do |r|
        expect(r.stdout).to match(/br-ci3/)
      end
    end

    it 'should have external_ids on br-ci3 bridge' do
      command('ovs-vsctl br-get-external-id br-ci3') do |r|
        expect(r.stdout).to match(/bridge-id=br-ci3/)
      end
    end

    it 'should get remote addr' do
      command('ovs-vsctl get Open_vSwitch . external_ids:ovn-remote') do |r|
        expect(r.stdout).to match(/\"tcp:127.0.0.1:2300\"/)
      end
    end
  end
end
