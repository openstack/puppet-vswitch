require 'spec_helper'

describe 'vswitch::ovs' do

  context 'on redhat with default parameters' do

    let :facts do
      {:osfamily => 'Redhat'}
    end

    it 'should contain the correct package and service' do

      should contain_service('openvswitch').with(
        :ensure => true,
        :enable => true,
        :name   => 'openvswitch'
      )

      should contain_package('openvswitch').with(
        :name   => 'openvswitch',
        :ensure => 'present',
        :before => 'Service[openvswitch]'
      )

    end
  end
end
