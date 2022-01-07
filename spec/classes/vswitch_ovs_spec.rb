require 'spec_helper'

describe 'vswitch::ovs' do

  let :default_params do {
    :package_ensure    => 'present',
    :dkms_ensure       => false,
    :enable_hw_offload => false,
    :disable_emc       => false,
  }
  end

  shared_examples_for 'vswitch::ovs' do
    context 'default parameters' do
      let (:params) { default_params }

      it 'contains the ovs class' do
        is_expected.to contain_class('vswitch::ovs')
      end

      it 'contains params' do
        is_expected.to contain_class('vswitch::params')
      end

      it 'clears hw-offload option' do
        is_expected.to contain_vs_config('other_config:hw-offload').with(
          :ensure => 'absent', :restart => true, :wait => true,
        )
      end

      it 'configures disable_emc option to false' do
          is_expected.to_not contain_vs_config('other_config:emc-insert-inv-prob')
      end

      it 'clears vlan-limit option' do
        is_expected.to contain_vs_config('other_config:vlan-limit').with(
          :value => nil, :wait => true,
        )
      end

      it 'configures service' do
        is_expected.to contain_service('openvswitch').with(
          :ensure    => true,
          :enable    => true,
          :name      => platform_params[:ovs_service_name],
          :hasstatus => platform_params[:service_hasstatus],
          :status    => platform_params[:service_status],
        )
      end

      it 'install package' do
        is_expected.to contain_package(platform_params[:ovs_package_name]).with(
          :name   => platform_params[:ovs_package_name],
          :ensure => params[:package_ensure],
          :before => 'Service[openvswitch]'
        )
      end
    end

    context 'custom parameters' do
      let :params do
        {
          :package_ensure    => 'latest',
          :dkms_ensure       => false,
          :enable_hw_offload => true,
          :disable_emc       => true,
          :vlan_limit        => 2,
        }
      end
      it 'installs correct package' do
        is_expected.to contain_package(platform_params[:ovs_package_name]).with(
          :name   => platform_params[:ovs_package_name],
          :ensure => 'latest',
          :before => 'Service[openvswitch]'
        )
      end
      it 'configures hw-offload option' do
          is_expected.to contain_vs_config('other_config:hw-offload').with(
            :value  => true, :restart => true, :wait => true,
          )
      end
      it 'configures disable_emc option' do
          is_expected.to contain_vs_config('other_config:emc-insert-inv-prob').with(
            :value  => 0, :wait => false,
          )
      end
      it 'configures vlan-limit option' do
          is_expected.to contain_vs_config('other_config:vlan-limit').with(
            :value  => 2, :wait => true,
          )
      end

    end
  end

  shared_examples_for "vswitch::ovs on Debian" do
    context 'with dkms ensure true' do
      let (:params) do
        {
          :package_ensure => 'latest',
          :dkms_ensure => true
        }
      end
      it 'install kernel module' do
        is_expected.to contain_package(platform_params[:ovs_dkms_package_name]).with(
          :name   => platform_params[:ovs_dkms_package_name],
          :ensure => params[:package_ensure],
        )
      end
      it 'rebuilds kernel module' do
        is_expected.to contain_exec('rebuild-ovsmod').with(
          :command     => '/usr/sbin/dpkg-reconfigure openvswitch-datapath-dkms > /tmp/reconf-log',
          :refreshonly => true,
        )
      end
    end
  end

  shared_examples_for "vswitch::ovs on RedHat" do
    it 'does not rebuild kernel module' do
        is_expected.to_not contain_exec('rebuild-ovsmod')
    end
  end

  shared_examples_for 'do not install dkms' do
    it 'does not rebuild kernel module' do
        is_expected.to_not contain_exec('rebuild-ovsmod')
    end
  end

  shared_examples_for 'install dkms' do
    it 'install kernel module' do
      is_expected.to contain_package(platform_params[:ovs_dkms_package_name]).with(
        :name   => platform_params[:ovs_dkms_package_name],
        :ensure => params[:package_ensure],
      )
    end
    it 'rebuilds kernel module' do
        is_expected.to contain_exec('rebuild-ovsmod').with(
          :command     => '/usr/sbin/dpkg-reconfigure openvswitch-datapath-dkms > /tmp/reconf-log',
          :refreshonly => true,
        )
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts({ :ovs_version => '1.4.2' }))
      end

      let (:platform_params) do
        case facts[:osfamily]
        when 'Debian'
          if facts[:operatingsystem] == 'Debian'
            {
              :ovs_package_name      => 'openvswitch-switch',
              :ovs_dkms_package_name => 'openvswitch-datapath-dkms',
              :ovs_service_name      => 'openvswitch-switch',
              :provider              => 'ovs',
              :service_hasstatus     => true,
            }
          elsif facts[:operatingsystem] == 'Ubuntu'
            {
              :ovs_package_name      => 'openvswitch-switch',
              :ovs_dkms_package_name => 'openvswitch-datapath-dkms',
              :ovs_service_name      => 'openvswitch-switch',
              :provider              => 'ovs',
              :service_hasstatus     => true,
            }
          end
        when 'RedHat'
          {
            :ovs_package_name      => 'openvswitch',
            :ovs_service_name      => 'openvswitch',
            :provider              => 'ovs_redhat',
          }
        end
      end

      it_behaves_like "vswitch::ovs"
      it_behaves_like "vswitch::ovs on #{facts[:osfamily]}"
    end
  end

end
