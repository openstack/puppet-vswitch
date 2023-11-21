require 'spec_helper'
require 'puppet'

describe 'range_to_mask', :type => :puppet_function do
  # run with param
  it { is_expected.to run.with_params('0-7,16-23,9').and_return('ff02ff') }
  it { is_expected.to run.with_params('0,16,32,48,64').and_return('10001000100010001') }
  # run with empty param
  it { is_expected.to run.with_params('').and_return(nil) }
  #run with params undefined
  it { is_expected.to run.with_params(:undef).and_return(nil) }
end
