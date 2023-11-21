require 'spec_helper'

describe Puppet::Type.type(:vs_bridge) do

  it "should support present as a value for ensure" do
    expect do
      described_class.new(:name => 'foo', :ensure => :present, :external_ids => 'foo=br-ex,blah-id=bar)')
    end.to_not raise_error
  end

end
