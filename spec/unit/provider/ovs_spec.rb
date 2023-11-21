require 'puppet'
require 'spec_helper'
require 'puppet/provider/ovs'

describe Puppet::Provider::Ovs do
  describe '#get_property' do
    it 'returns the property' do
      expect(described_class).to receive(:vsctl)
        .with('get', 'Port', 'testport', 'key')
        .and_return('value')
      expect(described_class.get_property('Port', 'testport', 'key')).to eq('value')
    end
    it 'returns the property without surrounding spaces' do
      expect(described_class).to receive(:vsctl)
        .with('get', 'Port', 'testport', 'key')
        .and_return('  value  ')
      expect(described_class.get_property('Port', 'testport', 'key')).to eq('value')
    end
  end

  describe '#set_property' do
    it 'sets the property' do
      expect(described_class).to receive(:vsctl)
        .with('set', 'Port', 'testport', 'key=value')
      described_class.set_property('Port', 'testport', 'key', 'value')
    end
    it 'sets the property (integer)' do
      expect(described_class).to receive(:vsctl)
        .with('set', 'Port', 'testport', 'key=1')
      described_class.set_property('Port', 'testport', 'key', 1)
    end
    it 'sets the property (boolean)' do
      expect(described_class).to receive(:vsctl)
        .with('set', 'Port', 'testport', 'key=true')
      described_class.set_property('Port', 'testport', 'key', true)
    end
    it 'clears the property when nil' do
      expect(described_class).to receive(:vsctl)
        .with('clear', 'Port', 'testport', 'key')
      described_class.set_property('Port', 'testport', 'key')
    end
    it 'clears the property when empty (string)' do
      expect(described_class).to receive(:vsctl)
        .with('clear', 'Port', 'testport', 'key')
      described_class.set_property('Port', 'testport', 'key', '')
    end
    it 'clears the property when empty (array)' do
      expect(described_class).to receive(:vsctl)
        .with('clear', 'Port', 'testport', 'key')
      described_class.set_property('Port', 'testport', 'key', [])
    end
  end

  describe '#get_other_config' do
    it 'returns the configs' do
      expect(described_class).to receive(:vsctl)
        .with('get', 'Port', 'testport', 'other_config')
        .and_return('{key1=value1,key2=value2}')
      expect(described_class.get_other_config('Port', 'testport', 'key1')).to eq('value1')
    end
    it 'returns the configs when not exist' do
      expect(described_class).to receive(:vsctl)
        .with('get', 'Port', 'testport', 'other_config')
        .and_return('{key1=value1,key2=value2}')
      expect(described_class.get_other_config('Port', 'testport', 'key3')).to eq(nil)
    end
  end

  describe '#set_other_config' do
    it 'sets the configs' do
      expect(described_class).to receive(:vsctl)
        .with('set', 'Port', 'testport', 'other_config:key=value')
      described_class.set_other_config('Port', 'testport', 'key', 'value')
    end
    it 'sets the configs (integer)' do
      expect(described_class).to receive(:vsctl)
        .with('set', 'Port', 'testport', 'other_config:key=1')
      described_class.set_other_config('Port', 'testport', 'key', 1)
    end
    it 'sets the configs (boolean)' do
      expect(described_class).to receive(:vsctl)
        .with('set', 'Port', 'testport', 'other_config:key=true')
      described_class.set_other_config('Port', 'testport', 'key', true)
    end
    it 'clears the configs when nil' do
      expect(described_class).to receive(:vsctl)
        .with('remove', 'Port', 'testport', 'other_config', 'key')
      described_class.set_other_config('Port', 'testport', 'key')
    end
    it 'clears the configs when empty (string)' do
      expect(described_class).to receive(:vsctl)
        .with('remove', 'Port', 'testport', 'other_config', 'key')
      described_class.set_other_config('Port', 'testport', 'key', '')
    end
    it 'clears the configs when empty (array)' do
      expect(described_class).to receive(:vsctl)
        .with('remove', 'Port', 'testport', 'other_config', 'key')
      described_class.set_other_config('Port', 'testport', 'key', [])
    end
  end

  describe '#parse_hash' do
    it 'parse hash value with default splitter' do
      expect(described_class.parse_hash('a=b,c=d')).to eq({'a' => 'b', 'c' => 'd'})
    end
    it 'parse hash value with custom splitter' do
      expect(described_class.parse_hash('a=b
c=d', "\n")).to eq({'a' => 'b', 'c' => 'd'})
    end
  end
end
