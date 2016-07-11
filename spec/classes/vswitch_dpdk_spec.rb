require 'spec_helper'

describe 'vswitch::dpdk' do

  let :default_params do {
    :package_ensure   => 'present',
    :core_list        => '1,2',
    :memory_channels  => '2'
  }
  end

  let :socket_mem_params do {
    :package_ensure   => 'present',
    :core_list        => '1,2',
    :memory_channels  => '2',
    :socket_mem       => '1024'
  }
  end

  let :redhat_platform_params do {
    :ovs_dpdk_package_name => 'openvswitch-dpdk',
    :ovs_service_name      => 'openvswitch',
    :provider              => 'ovs_redhat',
  }
  end

  shared_examples_for 'vswitch dpdk' do

    it 'contains params' do
      is_expected.to contain_class('vswitch::params')
    end

    it 'configures service' do
      is_expected.to contain_service('openvswitch').with(
        :ensure     => true,
        :enable     => true,
        :name       => platform_params[:ovs_service_name],
        :hasstatus  => platform_params[:service_hasstatus],
        :status     => platform_params[:service_status],
      )
    end

    it 'install package' do
      is_expected.to contain_package(platform_params[:ovs_dpdk_package_name]).with(
        :name     => platform_params[:ovs_dpdk_package_name],
        :ensure   => params[:package_ensure],
        :before   => 'Service[openvswitch]',
      )
    end

  end

  shared_examples_for 'vswitch dpdk mandatory params' do
    it 'configures dpdk options for ovs' do
      is_expected.to contain_file_line('/etc/sysconfig/openvswitch').with(
        :path   => '/etc/sysconfig/openvswitch',
        :match  => '^DPDK_OPTIONS.*',
        :line   => 'DPDK_OPTIONS = "-l 1,2 -n 2 "',
        :before => 'Service[openvswitch]',
      )
    end
  end

  shared_examples_for 'vswitch dpdk socket_mem param' do
    it 'configures dpdk options for ovs' do
      is_expected.to contain_file_line('/etc/sysconfig/openvswitch').with(
        :path   => '/etc/sysconfig/openvswitch',
        :match  => '^DPDK_OPTIONS.*',
        :line   => 'DPDK_OPTIONS = "-l 1,2 -n 2 --socket-mem 1024"',
        :before => 'Service[openvswitch]',
      )
    end
  end

  context 'on redhat with only mandatory parameters' do
    let :params do default_params end

    let :facts do
      OSDefaults.get_facts({
        :osfamily    => 'Redhat',
        :ovs_version => '1.4.2',
      })
    end

    let :platform_params do redhat_platform_params end

    it_configures 'vswitch dpdk'
    it_configures 'vswitch dpdk mandatory params'
  end

  context 'on redhat with additonal parameters' do
    let :params do socket_mem_params end

    let :facts do
      OSDefaults.get_facts({
        :osfamily    => 'Redhat',
        :ovs_version => '1.4.2',
      })
    end

    let :platform_params do redhat_platform_params end

    it_configures 'vswitch dpdk'
    it_configures 'vswitch dpdk socket_mem param'
  end

end