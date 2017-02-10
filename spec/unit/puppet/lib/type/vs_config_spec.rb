require 'spec_helper'

describe Puppet::Type.type(:vs_config) do
  it "should support present as a value for ensure" do
    expect do
      described_class.new(:name => 'foo', :ensure => :present)
    end.to_not raise_error
  end

  it "should support absent as a value for ensure" do
    expect do
      described_class.new(:name => 'foo', :ensure => :absent)
    end.to_not raise_error
  end

  it "wait property should accept boolean values" do
    expect do
      described_class.new({:name => "foo", :value => "[2, 1, 3, 0]", :ensure => :present, :wait => true})
    end.to_not raise_error
  end

  it "wait property should throw error for non boolean values" do
    expect do
      described_class.new({:name => "foo", :value => "123", :ensure => :present, :wait => "abc"})
    end.to raise_error(Puppet::Error)
  end

  it "skip_if_version param should accept string values of format \d+.\d+" do
    expect do
      described_class.new({:name => "foo", :value => "[2, 1, 3, 0]", :ensure => :present, :skip_if_version => '2.5'})
    end.to_not raise_error
    expect do
      described_class.new({:name => "foo", :value => "[2, 1, 3, 0]", :ensure => :present, :skip_if_version => 'a2.5'})
    end.to raise_error(Puppet::Error)
    expect do
      described_class.new({:name => "foo", :value => "[2, 1, 3, 0]", :ensure => :present, :skip_if_version => '2.5a'})
    end.to raise_error(Puppet::Error)
  end

  it "skip_if_version param should not accept non string values" do
    expect do
      described_class.new({:name => "foo", :value => "[2, 1, 3, 0]", :ensure => :present, :skip_if_version => 2.5})
    end.to raise_error(Puppet::Error)
  end

  it "should have a :value parameter" do
    expect(described_class.attrtype(:value)).to eq(:property)
  end

  it "should accept only string values" do
    expect do
      described_class.new({:name => "foo", :value => 123, :ensure => :present})
    end.to raise_error(Puppet::Error)
  end

  it "should munge array values" do
    expect(
      described_class.new({:name => "foo", :value => "[2, 1, 3, 0]", :ensure => :present})[:value]
      ).to eq "[0,1,2,3]"
  end
end
