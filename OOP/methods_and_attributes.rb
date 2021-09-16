# In fact, an asterisk in the list of formal parameters (on the last or only parameter) can likewise “collapse” a
# sequence of actual parameters into an array:
def my_method_1(a, b, *c)
  print a, b
  c.each do
  |x|
    print x
  end
  puts
end

my_method_1(1, 2, 3, 4, 5, 6, 7) # a=1, b=2, c=[3,4,5,6,7]

# Any other keyword parameter that's passed to the method will be added as a key to the
# options hash
def my_method_2(name: 'default', **options)
  options.merge!(name: name)
  puts options
end

my_method_2(name: 'Test', breed: 'Test', color: 'Test')

# Ruby has the capability to define methods on a per-object basis (rather than per class).
# Such methods are called singletons, and they belong solely to that object and have no effect on its class or superclasses.
# As an example, this might be useful in programming a GUI; you can define a button action for a widget
# by defining a singleton method for the button object.
str = "Hello, world!"
str_2 = "Goodbye!"

def str.spell
  self.chars.join('-')
end

puts str.spell # H-e-l-l-o-,- -w-o-r-l-d-!

