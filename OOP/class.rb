# Within the instance methods of a class, the pseudovariable self can be used as needed.
# This is only a reference to the current receiver, the object on which the instance method is invoked.

class MyClass
  attr_accessor :myvar # Replaces getmyvar, setmyvar and myvar=

  NAME = "Class Name" # class constant
  @@count = 0         # initialize a class variable

  def initialize      # called when object is allocated
    @@count += 1
    @myvar = 10
  end

  def self.getcount   # class method
    @@count           # class variable
  end

  def getcount        # instance returns class variable!
    @@count           # class variable
  end

  def getmyvar        # instance method
    @myvar            # instance variable
  end

  def setmyvar(val)   # instance method sets @myvar
    @myvar = val
  end

  def myvar=(val)     # Another way to set @myvar
    @myvar = val
  end
end

foo = MyClass.new # @myvar is 10
foo.setmyvar 20 # @myvar is 20
foo.myvar = 30 # @myvar is 30


# Access modifiers
#
# The modifying methods private, protected, and public can be used to control the visibility of methods in a class.
# (Instance variables are always private and inaccessible from outside the class, except by means of accessors.)
# Each of these modifiers takes a symbol like :foo as a parameter; if this is omitted, the modifier applies to all
# subsequent definitions in the class.

class MyClass
  def method1 #...
  end

  def method2 #...
  end

  def method3 #...
  end

  private :method1
  public :method2
  protected :method3

  private

  def my_method #...
  end

  def another_method #...
  end
end