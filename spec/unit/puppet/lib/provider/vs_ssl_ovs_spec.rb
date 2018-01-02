require 'spec_helper'

describe Puppet::Type.type(:vs_ssl).provider(:ovs) do
  let :ssl_attrs do
    {
      :name      => 'system',
      :ensure    => 'present',
    }
  end

  let :resource do
     Puppet::Type::Vs_ssl.new(ssl_attrs)
  end

  let :provider do
    described_class.new(resource)
  end

  context 'when changing cert_file' do
    it 'should recreate ssl config' do
      File.stubs(:file?).returns(true)
      provider.expects(:destroy)
      provider.expects(:create)
      provider.cert_file = '/tmp/blah.crt'
    end
  end

  context 'when changing key_file' do
    it 'should recreate ssl config' do
      File.stubs(:file?).returns(true)
      provider.expects(:destroy)
      provider.expects(:create)
      provider.key_file = '/tmp/blah.pem'
    end
  end

  context 'when changing ca_file' do
    it 'should recreate ssl config' do
      File.stubs(:file?).returns(true)
      provider.expects(:destroy)
      provider.expects(:create)
      provider.ca_file = '/tmp/blah.crt'
    end
  end

  context 'when creating with non-singleton name, system' do
    it 'should fail' do
      expect{described_class.new(Puppet::Type::Vs_ssl.new(
        {
          :name  => 'dummy',
          :ensure => :present})).create}.to raise_error(Puppet::Error)
    end
  end

end
