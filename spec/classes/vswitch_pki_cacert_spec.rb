require 'spec_helper'

describe 'vswitch::pki::cacert' do

  shared_examples_for 'vswitch::pki::cacert' do
    it 'shoud initialize ca authority' do
      is_expected.to contain_exec('ovs-pki-init-ca-authority').with(
        :command => 'ovs-pki init --force',
        :creates => '/var/lib/openvswitch/pki/switchca',
        :path    => ['/usr/sbin', '/sbin', '/usr/bin', '/bin'],
      )
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like "vswitch::pki::cacert"
    end
  end

end
