require 'spec_helper'

describe Puppet::Type.type(:vs_port) do

  it "should support only secure and standalone as a value for fail_mode" do
    expect do
      described_class.new(:name => 'foo', :ensure => :present, :fail_mode => 'secure')
    end.to_not raise_error
    expect do
      described_class.new(:name => 'foo', :ensure => :present, :fail_mode => 'standalone')
    end.to_not raise_error
    expect do
      described_class.new(:name => 'foo', :ensure => :present, :fail_mode => 'nomode')
    end.to raise_error(Puppet::ResourceError, /Invalid value/)
  end

end
