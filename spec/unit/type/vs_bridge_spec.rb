require 'spec_helper'

describe Puppet::Type.type(:vs_bridge) do

  it "should support present as a value for ensure" do
    expect do
      described_class.new(:name => 'foo', :ensure => :present)
    end.to_not raise_error
  end

  it "should support a string value for external_ids" do
    expect do
      described_class.new(:name => 'foo', :ensure => :present, :external_ids => 'foo=br-ex,blah-id=bar)')
    end.to_not raise_error
  end

  it "should support a hash value for external_ids" do
    expect do
      described_class.new(:name => 'foo', :ensure => :present, :external_ids => {'foo' => 'br-ex'})
    end.to_not raise_error
  end
end
