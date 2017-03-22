
# Converts the range to a mask
Puppet::Functions.create_function(:'range_to_mask') do

  dispatch :empty_param do
    param 'Pattern[/^$/]', :range
  end

  dispatch :range_param do
    param 'Pattern[/^[0-9\-\,]/]', :range
  end

  dispatch :undef_param do
    param 'Undef', :range
  end

  def empty_param(range)
    nil
  end

  def undef_param(range)
    nil
  end

  def range_param (range)
    range.to_s.split(",").map{|c| c.include?("-")?(c.split("-").map(&:to_i)[0]..c.split("-").map(&:to_i)[1]).to_a.join(","):c}.join(",").split(",").map{|c| 1<<c.to_i}.inject(0,:|).to_s(16)
  end
end

