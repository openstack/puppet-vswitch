require 'spec_helper'

describe Puppet::Type.type(:vs_bridge).provider(:ovs) do

  let(:resource_attrs) do
    {
      :name => 'testbr'
    }
  end

  let(:resource) do
    Puppet::Type::Vs_bridge.new(resource_attrs)
  end

  let(:provider) do
    described_class.new(resource)
  end

  describe '#exists?' do
    context 'if exists' do
      it 'returns true' do
        expect(described_class).to receive(:vsctl).with(
          'br-exists', 'testbr')
        expect(provider.exists?).to be_truthy
      end
    end

    context 'if not exists' do
      it 'returns false' do
        expect(described_class).to receive(:vsctl).with(
          'br-exists', 'testbr').and_raise(Puppet::ExecutionFailure, 'Error')
        expect(provider.exists?).to be_falsey
      end
    end
  end

  describe '#create' do
    context 'with defaults' do
      it 'creates a bridge' do
        expect(described_class).to receive(:vsctl).with(
          'add-br', 'testbr')
        expect(described_class).to receive(:ip).with(
          'link', 'set', 'dev', 'testbr', 'up')
        provider.create
      end
    end

    context 'with parameters' do
      before :each do
        resource_attrs.merge!(
          :external_ids   => {'k' => 'v'},
          :mac_table_size => 60000,
        )
      end
      it 'creates a bridge' do
        expect(described_class).to receive(:vsctl).with(
          'add-br', 'testbr')
        expect(described_class).to receive(:ip).with(
          'link', 'set', 'dev', 'testbr', 'up')

        expect(described_class).to receive(:vsctl).with(
          'br-get-external-id', 'testbr'
        ).and_return('')
        expect(described_class).to receive(:vsctl).with(
          'br-set-external-id', 'testbr', 'k', 'v'
        )

        expect(described_class).to receive(:vsctl).with(
          'set', 'Bridge', 'testbr', 'other_config:mac-table-size=60000'
        )

        provider.create
      end
    end
  end

  describe '#destroy' do
    it 'removes the bridge' do
      expect(described_class).to receive(:ip).with(
        'link', 'set', 'dev', 'testbr', 'down')
      expect(described_class).to receive(:vsctl).with(
        'del-br', 'testbr')
      provider.destroy
    end
  end

  describe '#external_ids' do
    it 'returns external_ids' do
      expect(described_class).to receive(:vsctl).with(
        'br-get-external-id', 'testbr'
      ).and_return(
        'k=v'
      )
      expect(provider.external_ids).to eq({'k' => 'v'})
    end
  end

  describe '#external_ids=' do
    it 'configures external ids' do
      expect(described_class).to receive(:vsctl).with(
        'br-get-external-id', 'testbr'
      ).and_return('')
      expect(described_class).to receive(:vsctl).with(
        'br-set-external-id', 'testbr', 'k', 'v'
      )
      provider.external_ids = {'k' => 'v'}
    end

    it 'configures external ids when ids already exist' do
      expect(described_class).to receive(:vsctl).with(
        'br-get-external-id', 'testbr'
      ).and_return('k1=v1
k2=v2
k3=v3')
      expect(described_class).to receive(:vsctl).with(
        'br-set-external-id', 'testbr', 'k2', 'v2new'
      )
      expect(described_class).to receive(:vsctl).with(
        'br-set-external-id', 'testbr', 'k3'
      )
      provider.external_ids = {'k1' => 'v1', 'k2' => 'v2new'}
    end
  end

  describe '#mac_table_size' do
    it 'returns mac table size' do
      expect(described_class).to receive(:vsctl).with(
        'get', 'Bridge', 'testbr', 'other_config'
      ).and_return(
        '{disable-in-band="true", mac-table-size="50000"}'
      )
      expect(provider.mac_table_size).to eq(50000)
    end
  end

  describe '#mac_table_size=' do
    it 'sets mac table size' do
      expect(described_class).to receive(:vsctl).with(
        'set', 'Bridge', 'testbr', 'other_config:mac-table-size=60000'
      )
      provider.mac_table_size = 60000
    end
  end
end
