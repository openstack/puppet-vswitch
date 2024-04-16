require 'spec_helper'

describe 'vswitch::pki::cert' do

  let(:title) {'foo'}

  shared_examples_for 'vswitch::pki::cert' do
    it 'shoud generate a certificate' do
      is_expected.to contain_exec('ovs-req-and-sign-cert-foo').with(
        :command => ['ovs-pki', 'req+sign', 'foo'],
        :cwd     => '/etc/openvswitch',
        :creates => '/etc/openvswitch/foo-cert.pem',
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

      it_behaves_like "vswitch::pki::cert"
    end
  end

end
