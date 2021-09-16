# It is also possible to pass parameters via yield, which will be substituted into the block’s parameter list (between vertical bars)
def my_sequence
  (1..10).each do |i|
    yield i
  end
end

my_sequence { |x| puts x**2 }