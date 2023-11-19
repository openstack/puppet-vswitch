require 'spec_helper'

describe Puppet::Type.type(:vs_port).provider(:ovs) do

  let(:resource_attrs) do
    {
      :name   => 'testport',
      :bridge => 'testbr'
    }
  end

  let(:resource) do
    Puppet::Type::Vs_port.new(resource_attrs)
  end

  let(:provider) do
    described_class.new(resource)
  end

  describe '#exists?' do
    context 'if exists' do
      it 'returns true' do
        expect(described_class).to receive(:vsctl).with(
          'list-ports', 'testbr'
        ).and_return('testport
anothertestport
yetanothertestport')
        expect(provider.exists?).to be_truthy
      end
    end

    context 'if not exists' do
      it 'returns false' do
        expect(described_class).to receive(:vsctl).with(
          'list-ports', 'testbr'
        ).and_return('anothertestport
yetanothertestport')
        expect(provider.exists?).to be_falsey
      end
    end
  end

  # TODO(tkajinam): Create test cases for create

  describe '#destroy' do
    it 'removes the port' do
      expect(described_class).to receive(:vsctl).with(
        'del-port', 'testbr', 'testport')
      provider.destroy
    end
  end

  describe '#interface' do
    it 'returns interface' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'get', 'Port', 'testport', 'interfaces'
      ).and_return('[c9b76714-e353-4b02-ae0f-36b9e6fce5af]')
      expect(described_class).to receive(:vsctl).with(
        'get', 'Interface', 'c9b76714-e353-4b02-ae0f-36b9e6fce5af', 'name'
      ).and_return('testif')

      expect(provider.interface).to eq(['testif'])
    end
  end

  describe '#bond_mode' do
    it 'returns bond mode' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'get', 'Port', 'testport', 'bond_mode'
      ).and_return('balance-slb')
      expect(provider.bond_mode).to eq('balance-slb')
    end
  end

  describe '#bond_mode=' do
    it 'configures bond mode' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'set', 'Port', 'testport', 'bond_mode=balance-slb')
      provider.bond_mode = 'balance-slb'
    end
    it 'clears bond mode' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'clear', 'Port', 'testport', 'bond_mode')
      provider.bond_mode = ''
    end
  end

  describe '#lacp' do
    it 'returns lacp' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'get', 'Port', 'testport', 'lacp'
      ).and_return('active')
      expect(provider.lacp).to eq('active')
    end
  end

  describe '#lacp=' do
    it 'configures lacp' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'set', 'Port', 'testport', 'lacp=active')
      provider.lacp = 'active'
    end
  end

  describe '#lacp_time' do
    it 'returns lacp_time' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'get', 'Port', 'testport', 'other_config:lacp-time'
      ).and_return('fast')
      expect(provider.lacp_time).to eq('fast')
    end
  end

  describe '#lacp_time=' do
    it 'configures lacp_time' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'set', 'Port', 'testport', 'other_config:lacp-time=fast')
      provider.lacp_time = 'fast'
    end
    it 'clears lacp_time' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'remove', 'Port', 'testport', ['other_config', 'lacp-time'])
      provider.lacp_time = ''
    end
  end

  describe '#vlan_mode' do
    it 'returns vlan_mode' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'get', 'Port', 'testport', 'vlan_mode'
      ).and_return('native-tagged')
      expect(provider.vlan_mode).to eq('native-tagged')
    end
  end

  describe '#vlan_mode=' do
    it 'configures vlan_mode' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'set', 'Port', 'testport', 'vlan_mode=native-tagged')
      provider.vlan_mode = 'native-tagged'
    end
    it 'clears vlan_mode' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'clear', 'Port', 'testport', 'vlan_mode')
      provider.vlan_mode = ''
    end
  end

  describe '#vlan_tag' do
    it 'returns vlan_tag' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'get', 'Port', 'testport', 'tag'
      ).and_return('100')
      expect(provider.vlan_tag).to eq('100')
    end
  end

  describe '#vlan_tag=' do
    it 'configures vlan_tag' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'set', 'Port', 'testport', 'tag=100')
      provider.vlan_tag = '100'
    end
    it 'clears vlan_tag' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'clear', 'Port', 'testport', 'tag')
      provider.vlan_tag = ''
    end
  end

  describe '#vlan_trunks' do
    it 'returns vlan_trunks' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'get', 'Port', 'testport', 'trunks'
      ).and_return('[0 1 2]')
      expect(provider.vlan_trunks).to eq(['0', '1', '2'])
    end
  end

  describe '#vlan_trunks=' do
    it 'configures vlan_trunks' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'set', 'Port', 'testport', 'trunks=0 1 2')
      provider.vlan_trunks = ['0', '1', '2']
    end
    it 'clears vlan_trunks' do
      expect(described_class).to receive(:vsctl).with(
        '--if-exists', 'clear', 'Port', 'testport', 'trunks')
      provider.vlan_trunks = []
    end
  end
end
