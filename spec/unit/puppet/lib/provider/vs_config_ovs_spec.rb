require 'spec_helper'

describe Puppet::Type.type(:vs_config).provider(:ovs) do
  it 'should have an instance method' do
    expect(described_class).to respond_to :instances
  end

  it 'should have a prefetch method' do
    expect(described_class).to respond_to :prefetch
  end

  context "Testing string values" do
    before :each do
      described_class.expects(:vsctl).with(
        "list", "Open_vSwitch", ".").returns 'key1     : value1
key2     : value2
key3     : value3'
    end

    it "should return three resources" do
      expect(described_class.instances.size).to eq(3)
    end

    it "should return the appropriate property hash" do
      described_class.instances.each do |inst|
        _inst = inst.instance_variable_get("@property_hash")
        expect(_inst.key?(:name)).to eq true
        expect(_inst.key?(:value)).to eq true
        expect(_inst.key?(:ensure)).to eq true
      end
    end

    it "should contain proper values" do
      described_class.instances.each do |inst|
        _inst = inst.instance_variable_get("@property_hash")
        expect(_inst[:name][0..2]).to eq "key"
        expect(_inst[:value][0..4]).to eq "value"
        expect(_inst[:value][5]).to eq _inst[:name][3]
        expect(_inst[:ensure]).to eq :present
      end
    end
  end

  context "Testing array values" do
    before :each do
      described_class.expects(:vsctl).with(
        "list", "Open_vSwitch", ".").returns 'key1        : [abc, def, ghi]
key2     : [def, abc, ghi]
key3     : [1001, 399, 240, 1200]'
      end

    it "should return three resources" do
      expect(described_class.instances.size).to eq(3)
    end

    it "should contain proper values" do
      expected_values = {
          "key1" => "[abc,def,ghi]",
          "key2" => "[abc,def,ghi]",
          "key3" => "[1001,1200,240,399]"
      }
      described_class.instances.each do |inst|
        _inst = inst.instance_variable_get("@property_hash")
        expect(expected_values.key?(_inst[:name])).to eq true
        expect(_inst[:value]).to eq expected_values[_inst[:name]]
        expect(_inst[:ensure]).to eq :present
      end
    end
  end

  context "Testing hash values" do
    before :each do
      described_class.expects(:vsctl).with(
        "list", "Open_vSwitch", ".").returns 'key1        : {}
key2     : {"hash21"="value21"}
key3     : {"hash31"="value31", "hash32"="value32", "hash33"=33}'
      end

    it "should return three resources" do
      expect(described_class.instances.size).to eq(4)
    end

    it "should contain valid names and values" do
      expected_values = {
        "key2:hash21" => "value21",
        "key3:hash31" => "value31",
        "key3:hash32" => "value32",
        "key3:hash33" => "33"}
      described_class.instances.each do |inst|
        _inst = inst.instance_variable_get("@property_hash")
        expect(expected_values.key?(_inst[:name])).to eq true
        expect(_inst[:value]).to eq expected_values[_inst[:name]]
        expect(_inst[:ensure]).to eq :present
      end
    end
  end

end
