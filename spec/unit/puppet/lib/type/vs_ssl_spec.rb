require 'spec_helper'

describe Puppet::Type.type(:vs_ssl) do
  it "should support present as a value for ensure" do
    expect do
      described_class.new(:name => 'system', :ensure => :present)
    end.to_not raise_error
  end

  it "should accept key_file, cert_file, ca_file, bootstrap options" do
    expect do
      described_class.new({
        :name      => 'system',
        :ensure    => :present,
        :key_file  => '/tmp/dummyfile.pem',
        :cert_file => '/tmp/dummyfile.crt',
        :ca_file   => '/tmp/dummyca.crt',
        :bootstrap  => false})
    end.to_not raise_error
  end
end
