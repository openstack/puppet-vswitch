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
        params.merge!(:socket_limit    => '')
        params.merge!(:memory_channels => '' )
        params.merge!(:pmd_core_list => '')
        params.merge!(:enable_hw_offload => false)
        params.merge!(:disable_emc => false)
      end
      it 'configures dpdk options' do
        is_expected.to contain_vs_config('other_config:dpdk-init').with(
          :value  => true, :wait => true,
        )
        is_expected.to contain_vs_config('other_config:pmd-cpu-mask').with(
          :value  => nil, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-mem').with(
          :value => '', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-limit').with(
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
        is_expected.to contain_vs_config('other_config:emc-insert-inv-prob').with(
          :ensure => 'absent', :wait => false
        )
        is_expected.to contain_vs_config('other_config:vlan-limit').with(
          :value => nil, :wait => true,
        )
        is_expected.to contain_vs_config('other_config:userspace-tso-enable').with(
          :ensure => 'absent', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:vhost-postcopy-support').with(
          :ensure => 'absent', :restart => true, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:pmd-auto-lb').with(
          :ensure => 'absent', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:pmd-auto-lb-rebal-interval').with(
          :ensure => 'absent', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:pmd-auto-lb-load-threshold').with(
          :ensure => 'absent', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:pmd-auto-lb-improvement-threshold').with(
          :ensure => 'absent', :wait => false,
        )
      end
      it 'restarts the service when needed' do
        is_expected.to contain_exec('restart openvswitch').with(
          :path        => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
          :command     => "systemctl -q restart %s.service" % platform_params[:ovs_service_name],
          :refreshonly => true
        )
      end
    end

    context 'when passing all params' do
      before :each do
        params.merge!({
          :host_core_list                    => '1,2',
          :socket_mem                        => '1024,1024',
          :socket_limit                      => '2048,2048',
          :memory_channels                   => 2,
          :pmd_core_list                     => '22,23,24,25,66,67,68,69',
          :enable_hw_offload                 => true,
          :disable_emc                       => true,
          :vlan_limit                        => 2,
          :enable_tso                        => true,
          :vhost_postcopy_support            => true,
          :pmd_auto_lb                       => true,
          :pmd_auto_lb_rebal_interval        => 1,
          :pmd_auto_lb_load_threshold        => 95,
          :pmd_auto_lb_improvement_threshold => 25,
        })
      end
      it 'configures dpdk options' do
        is_expected.to contain_vs_config('other_config:dpdk-init').with(
          :value  => true, :wait => true,
        )
        is_expected.to contain_vs_config('other_config:pmd-cpu-mask').with(
          :value  => '3c0000000003c00000', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-mem').with(
          :value => '1024,1024', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-limit').with(
          :value => '2048,2048', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-lcore-mask').with(
          :value => '6', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-extra').with(
          :value => '-n 2', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:hw-offload').with(
          :value  => true, :restart => true, :wait => true,
        )
        is_expected.to contain_vs_config('other_config:emc-insert-inv-prob').with(
          :value  => 0, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:vlan-limit').with(
          :value  => 2, :wait => true,
        )
        is_expected.to contain_vs_config('other_config:userspace-tso-enable').with(
          :value => true, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:vhost-postcopy-support').with(
          :value => true, :restart => true, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:pmd-auto-lb').with(
          :value => true, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:pmd-auto-lb-rebal-interval').with(
          :value => 1, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:pmd-auto-lb-load-threshold').with(
          :value => 95, :wait => false,
        )
        is_expected.to contain_vs_config('other_config:pmd-auto-lb-improvement-threshold').with(
          :value => 25, :wait => false,
        )
      end
    end

    context 'when passing arrays' do
      before :each do
        params.merge!({
          :socket_mem   => [1024, 1024],
          :socket_limit => [2048, 2048],
        })
      end

      it 'configures dpdk options with comma-separated lists' do
        is_expected.to contain_vs_config('other_config:dpdk-socket-mem').with(
          :value => '1024,1024', :wait => false,
        )
        is_expected.to contain_vs_config('other_config:dpdk-socket-limit').with(
          :value => '2048,2048', :wait => false,
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
