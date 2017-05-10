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
    context 'shall  write DPDK_OPTIONS as well as ovsdb params' do
      it 'include the class' do
        is_expected.to contain_class('vswitch::dpdk')
      end

      it 'contains params' do
        is_expected.to contain_class('vswitch::params')
      end

      it 'configures service' do
        is_expected.to contain_service('openvswitch').with(
          :ensure     => true,
          :enable     => true,
          :name       => platform_params[:ovs_service_name],
        )
      end

      it 'install package' do
        is_expected.to contain_package(platform_params[:ovs_dpdk_package_name]).with(
          :name     => platform_params[:ovs_dpdk_package_name],
          :ensure   => params[:package_ensure],
          :before   => 'Service[openvswitch]',
        )
      end

      it 'should have dpdk driver modules file' do
        is_expected.to contain_kmod__load('vfio-pci')
      end
      it 'configures dpdk options with socket memory' do
        is_expected.to contain_file_line('/etc/sysconfig/openvswitch')

        is_expected.to contain_vs_config('other_config:dpdk-init').with(
          :value  => 'true', :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:pmd-cpu-mask').with(
          :value  => nil, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-mem').with(
          :value => nil, :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:dpdk-lcore-mask').with(
          :value => nil, :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:dpdk-extra').with(
          :value => nil, :wait => false, :skip_if_version => "2.5",
        )
      end
    end

    context 'when passing all empty params' do
      before :each do
        params.merge!(:host_core_list  => '')
        params.merge!(:socket_mem      => '')
        params.merge!(:memory_channels => '' )
        params.merge!(:pmd_core_list => '')
      end
      it 'configures dpdk options' do
        is_expected.to contain_file_line('/etc/sysconfig/openvswitch').with(
          :path   => '/etc/sysconfig/openvswitch',
          :match  => '^DPDK_OPTIONS.*',
          :before => 'Service[openvswitch]',
        )
        is_expected.to contain_vs_config('other_config:dpdk-init').with(
          :value  => 'true', :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:pmd-cpu-mask').with(
          :value  => nil, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-mem').with(
          :value => '', :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:dpdk-lcore-mask').with(
          :value => nil, :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:dpdk-extra').with(
          :value => nil, :wait => false, :skip_if_version => "2.5",
        )

      end
    end

    context 'when passing all params' do
      before :each do
        params.merge!(:host_core_list  => '1,2')
        params.merge!(:socket_mem      => '1024')
        params.merge!(:memory_channels => 2)
        params.merge!(:pmd_core_list => '22,23,24,25,66,67,68,69')
      end
      it 'configures dpdk options' do
        is_expected.to contain_file_line('/etc/sysconfig/openvswitch').with(
          :path   => '/etc/sysconfig/openvswitch',
          :match  => '^DPDK_OPTIONS.*',
          :line   => 'DPDK_OPTIONS = "-l 1,2 -n 2 --socket-mem 1024 "',
          :before => 'Service[openvswitch]',
        )
        is_expected.to contain_vs_config('other_config:dpdk-init').with(
          :value  => 'true', :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:pmd-cpu-mask').with(
          :value  => '3c0000000003c00000', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-mem').with(
          :value => '1024', :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:dpdk-lcore-mask').with(
          :value => '6', :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:dpdk-extra').with(
          :value => '-n 2', :wait => false, :skip_if_version => "2.5",
        )
      end
    end

    context 'when passing invalid socket_mem' do
      before :each do
        params.merge!(:socket_mem      => "'1024'")
      end
      it { is_expected.to raise_error(Puppet::Error, /socket_mem is in incorrect format/) }
    end

    context 'when providing valid driver type facts' do
      let :facts do
        OSDefaults.get_facts({
          :osfamily                => 'Redhat',
          :operatingsystem         => 'RedHat',
          :ovs_version             => '2.5.1',
          :pci_address_driver_test => '0000:00:05.0,0000:00:05.1'
        })
      end

      before :each do
        params.merge!(:host_core_list  => '1,2')
        params.merge!(:driver_type     => 'test')
        params.merge!(:memory_channels => 2)
      end
      it 'configures dpdk options with pci address for driver test' do
        is_expected.to contain_file_line('/etc/sysconfig/openvswitch').with(
          :path   => '/etc/sysconfig/openvswitch',
          :match  => '^DPDK_OPTIONS.*',
          :line   => 'DPDK_OPTIONS = "-l 1,2 -n 2  -w 0000:00:05.0 -w 0000:00:05.1"',
          :before => 'Service[openvswitch]',
        )
        is_expected.to contain_vs_config('other_config:dpdk-init').with(
          :value  => 'true', :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:pmd-cpu-mask').with(
          :value  => nil, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-mem').with(
          :value => nil, :wait => false, :skip_if_version => "2.5",
        )
        is_expected.to contain_vs_config('other_config:dpdk-lcore-mask').with(
          :value => '6', :wait => false, :skip_if_version => "2.5",
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
