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
