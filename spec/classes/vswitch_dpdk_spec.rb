require 'spec_helper'

describe 'vswitch::dpdk' do

  let :default_params do {
    :package_ensure   => 'present',
  }
  end

  shared_examples_for 'vswitch::dpdk on Debian' do
    let(:params) { default_params }
    context 'basic parameters' do
      before :each do
        params.merge!(:host_core_list => '1,2')
      end

      it_raises 'a Puppet::Error', /Debian not yet supported for dpdk/
    end
  end

  shared_examples_for 'vswitch::dpdk on RedHat' do
    let(:params) { default_params }

    context 'when passing all empty params' do
      before :each do
        params.merge!(:host_core_list  => '')
        params.merge!(:socket_mem      => '')
        params.merge!(:memory_channels => '' )
        params.merge!(:pmd_core_list => '')
        params.merge!(:enable_hw_offload => false)
        params.merge!(:disable_emc => false)
      end
      it 'configures dpdk options' do
        is_expected.to contain_vs_config('other_config:dpdk-init').with(
          :value  => 'true', :wait => true,
        )
        is_expected.to contain_vs_config('other_config:pmd-cpu-mask').with(
          :value  => nil, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-mem').with(
          :value => '', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-lcore-mask').with(
          :value => nil, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-extra').with(
          :value => nil, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:hw-offload').with(
          :ensure => 'absent', :restart => true, :wait => true,
        )
        is_expected.to_not contain_vs_config('other_config:emc-insert-inv-prob')
        is_expected.to_not contain_vs_config('other_config:vlan-limit')

      end
    end

    context 'when passing all params' do
      before :each do
        params.merge!(:host_core_list  => '1,2')
        params.merge!(:socket_mem      => '1024')
        params.merge!(:memory_channels => 2)
        params.merge!(:pmd_core_list => '22,23,24,25,66,67,68,69')
        params.merge!(:enable_hw_offload => true)
        params.merge!(:disable_emc => true)
        params.merge!(:vlan_limit => 2)
      end
      it 'configures dpdk options' do
        is_expected.to contain_vs_config('other_config:dpdk-init').with(
          :value  => 'true', :wait => true,
        )
        is_expected.to contain_vs_config('other_config:pmd-cpu-mask').with(
          :value  => '3c0000000003c00000', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-mem').with(
          :value => '1024', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-lcore-mask').with(
          :value => '6', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-extra').with(
          :value => '-n 2', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:hw-offload').with(
          :value  => 'true', :restart => true, :wait => true,
        )
        is_expected.to contain_vs_config('other_config:emc-insert-inv-prob').with(
          :value  => '0', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:vlan-limit').with(
          :value  => '2', :wait => true,
        )
      end
    end

  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts({ :ovs_version => '2.6.1' }))
      end
      let (:platform_params) do
        case facts[:osfamily]
        when 'Debian'
          {
            # not supported
          }
        when 'RedHat'
          {
            :ovs_dpdk_package_name => 'openvswitch',
            :ovs_service_name      => 'openvswitch',
            :provider              => 'ovs_redhat',
            :ovsdb_service_name    => 'ovsdb-server',
          }
        end
      end
      it_behaves_like "vswitch::dpdk on #{facts[:osfamily]}"
    end
  end
end
