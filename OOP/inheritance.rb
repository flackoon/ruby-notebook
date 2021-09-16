# include/extend

# A mixin is a way of getting some of the benefits of multiple inheritance without dealing with all the difficulties.
# It can be considered a restricted form of multiple inheritance, but the language creator Matz has called it
# “single inheritance with implementation sharing.”
#
#
# Note that 'include' adds features of a module to the current space;
# the 'extend' method adds features of a module to an object.
#
# With 'include', the module’s methods become available as instance methods;
# with 'extend', they become available as class methods.



# require/load

# We should mention that 'load' and 'require' do not relate to modules but rather to Ruby source and
# binary files (statically or dynamically loadable). A 'load' operation reads a file and runs it in the current context
# so that its definitions become available at that point. A 'require' operation is similar to a load, but it will not
# load a file if it has already been loaded.



# Inheritance

class OtherClass
  def present
    puts "My name is OtherClass"
  end
end

class MyClass < OtherClass
  # In addition to using built-in methods, it is only natural to define your own and also to redefine and override existing ones.
  # When you define a method with the same name as an existing one, the previous method is overridden.
  # If a method needs to call the “parent” method that it overrides (a frequent occurrence), the keyword super can be used for this purpose.
  def present
    super # call OtherClass.present
    puts "No, my name is MyClass"
  end

  def sophisticated_method
    puts "Easy boy"
  end
  alias_method :easy_method, :sophisticated_method

end

x = MyClass.new
x.present
x.easy_method