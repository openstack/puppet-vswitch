require 'spec_helper'

describe 'vswitch::ovs' do

  let :default_params do {
    :package_ensure => 'present',
  }
  end

  let :redhat_platform_params do {
    :ovs_package_name      => 'openvswitch',
    :ovs_service_name      => 'openvswitch',
    :provider              => 'ovs_redhat',
  }
  end

  let :debian_platform_params do {
    :ovs_package_name      => 'openvswitch-switch',
    :ovs_dkms_package_name => 'openvswitch-datapath-dkms',
    :ovs_service_name      => 'openvswitch-switch',
    :provider              => 'ovs',
    :service_hasstatus     => false,
    :service_status        => '/etc/init.d/openvswitch-switch status | fgrep -q "not running"; if [ $? -eq 0 ]; then exit 1; else exit 0; fi',
  }
  end

  let :ubuntu_platform_params do {
    :ovs_package_name      => 'openvswitch-switch',
    :ovs_dkms_package_name => 'openvswitch-datapath-dkms',
    :ovs_service_name      => 'openvswitch-switch',
    :provider              => 'ovs',
    :service_hasstatus     => false,
    :service_status        => '/sbin/status openvswitch-switch | fgrep "start/running"',
  }
  end

  let :freebsd_platform_params do {
    :ovs_package_name      => 'openvswitch',
    :ovs_service_name      => 'ovs-vswitchd',
    :ovsdb_service_name    => 'ovsdb-server',
    :provider              => 'ovs',
    :service_hasstatus     => nil,
    :ovsdb_hasstatus       => nil,
    :service_status        => '/usr/sbin/service ovs-vswitchd onestatus',
    :ovsdb_status          => '/usr/sbin/service ovsdb-server onestatus',
  }
  end

  let :solaris_platform_params do {
    :ovs_package_name      => 'service/network/openvswitch',
    :ovs_service_name      => 'application/openvswitch/vswitch-server:default',
    :ovsdb_service_name    => 'application/openvswitch/ovsdb-server:default',
    :provider              => 'ovs',
    :service_hasstatus     => nil,
    :ovsdb_hasstatus       => nil,
    :service_status        => '/usr/bin/svcs -H -o state application/openvswitch/vswitch-server:default | grep online',
    :ovsdb_status          => '/usr/bin/svcs -H -o state application/openvswitch/ovsdb-server:default | grep online',
  }
  end

  shared_examples_for 'vswitch ovs' do
    it 'contains params' do
        is_expected.to contain_class('vswitch::params')
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

  context 'on redhat with default parameters' do
    let :params do default_params end

    let :facts do
      OSDefaults.get_facts({
        :osfamily    => 'Redhat',
        :ovs_version => '1.4.2',
      })
    end

    let :platform_params do redhat_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'do not install dkms'
  end

  context 'on redhat with parameters' do
    let :params do {
      :package_ensure => 'latest',
      :dkms_ensure    => false,
    }
    end

    let :facts do
      OSDefaults.get_facts({
        :osfamily    => 'Redhat',
        :ovs_version => '1.4.2',
      })
    end
    let :platform_params do redhat_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'do not install dkms'
  end

  context 'on Debian with default parameters' do
    let :params do default_params end

    let :facts do
      OSDefaults.get_facts({
        :operatingsystem => 'Debian',
        :osfamily        => 'Debian',
        :ovs_version     => '1.4.2',
      })
    end
    let :platform_params do debian_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'do not install dkms'
  end

  context 'on Debian with parameters' do
    let :params do {
      :package_ensure => 'latest',
      :dkms_ensure    => true,
    }
    end

    let :facts do
      OSDefaults.get_facts({
        :operatingsystem => 'Debian',
        :osfamily        => 'Debian',
        :ovs_version     => '1.4.2',
      })
    end
    let :platform_params do debian_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'install dkms'
  end

  context 'on Ubuntu with default parameters' do
    let :params do default_params end

    let :facts do
      OSDefaults.get_facts({
        :operatingsystem           => 'Ubuntu',
        :operatingsystemmajrelease => '14',
        :osfamily                  => 'Debian',
        :ovs_version               => '1.4.2',
      })
    end
    let :platform_params do ubuntu_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'do not install dkms'
  end

  context 'on Ubuntu with parameters' do
    let :params do {
      :package_ensure => 'latest',
      :dkms_ensure    => true,
    }
    end

    let :facts do
      OSDefaults.get_facts({
        :operatingsystem           => 'Ubuntu',
        :operatingsystemmajrelease => '14',
        :osfamily                  => 'Debian',
        :ovs_version               => '1.4.2',
      })
    end
    let :platform_params do ubuntu_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'install dkms'
  end

  context 'on FreeBSD with default parameters' do
    let :params do default_params end

    let :facts do
      OSDefaults.get_facts({
        :osfamily        => 'FreeBSD',
        :operatingsystem => 'FreeBSD',
        :ovs_version     => '1.4.2',
      })
    end
    let :platform_params do freebsd_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'do not install dkms'

    it 'configures ovsdb service' do
        is_expected.to contain_service('ovsdb-server').with(
          :ensure    => true,
          :enable    => true,
          :name      => platform_params[:ovsdb_service_name],
          :hasstatus => platform_params[:ovsdb_hasstatus],
          :status    => platform_params[:ovsdb_status],
        )
    end
  end

  context 'on FreeBSD with parameters' do
    let :params do {
      :package_ensure => 'latest',
    }
    end

    let :facts do
      OSDefaults.get_facts({
        :osfamily        => 'FreeBSD',
        :operatingsystem => 'FreeBSD',
        :ovs_version     => '1.4.2',
      })
    end
    let :platform_params do freebsd_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'do not install dkms'

    it 'configures ovsdb service' do
        is_expected.to contain_service(platform_params[:ovsdb_service_name]).with(
          :ensure    => true,
          :enable    => true,
          :name      => platform_params[:ovsdb_service_name],
          :hasstatus => platform_params[:ovsdb_hasstatus],
          :status    => platform_params[:ovsdb_status],
        )
    end

    it 'ovs-vswitchd requires ovsdb-server' do
      is_expected.to contain_service(platform_params[:ovsdb_service_name]).that_notifies("Service[#{platform_params[:ovs_package_name]}]")
    end
  end

  context 'on Solaris with default parameters' do
    let :params do default_params end

    let :facts do
      OSDefaults.get_facts({
        :osfamily        => 'Solaris',
        :operatingsystem => 'Solaris',
        :ovs_version     => '2.3.1',
      })
    end
    let :platform_params do solaris_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'do not install dkms'

    it 'configures ovsdb service' do
        is_expected.to contain_service('ovsdb-server').with(
          :ensure    => true,
          :enable    => true,
          :name      => platform_params[:ovsdb_service_name],
          :hasstatus => platform_params[:ovsdb_hasstatus],
          :status    => platform_params[:ovsdb_status],
        )
    end
  end

  context 'on Solaris with parameters' do
    let :params do {
      :package_ensure => 'latest',
    }
    end

    let :facts do
      OSDefaults.get_facts({
        :osfamily        => 'Solaris',
        :operatingsystem => 'Solaris',
        :ovs_version     => '2.3.1',
      })
    end
    let :platform_params do solaris_platform_params end

    it_configures 'vswitch ovs'
    it_configures 'do not install dkms'

    it 'configures ovsdb service' do
        is_expected.to contain_service('ovsdb-server').with(
          :ensure    => true,
          :enable    => true,
          :name      => platform_params[:ovsdb_service_name],
          :hasstatus => platform_params[:ovsdb_hasstatus],
          :status    => platform_params[:ovsdb_status],
        )
    end
  end

end
