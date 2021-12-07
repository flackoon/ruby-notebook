# OOP and Dynamic Features in Ruby

1. [Everyday OOP Tasks](#)\
   1.1. [Using Multiple Constructors](#)\
   1.2. [Creating Instance Attributes](#)\
   1.3. [Using more Elaborate Constructors](#)\
   1.4. [Creating Class-Level Attributes and Methods](#)\
   1.5. [Inheriting from a Superclass](#)\
   1.6. [Testing Classes of Objects](#)\
   1.7. [Testing Equality of Objects](#)\
   1.8. [Controlling Access to Methods](#)\
   1.9. [Copying an Object](#)\
   1.10. [Using initialize_copy](#)\
   1.11. [Understanding allocate](#)\
   1.12. [Working with Modules](#)\
   1.13. [Transforming or Converting Objects](#)\
   1.14. [Creating Data-Only Classes (Structs)](#)\
   1.15. [Freezing Objects](#)\
   1.16. [Using tap in Method Chaining](#)
2. [More Advanced Techniques](#)\
   2.1. [Sending an Explicit Message to an Object](#)\
   2.2. [Specializing an Individual Object](#)\
   2.3. [Nesting Classes and Modules](#)\
   2.4. [Creating Parametric Classes](#)\
   2.5. [Storing Code as Proc Objects](#)\
   2.6. [Storing Code as Method Objects](#)\
   2.7. [Using Symbols as Blocks](#)\
   2.8. [How Module Inclusion Works](#)\
   2.9. [Detecting Default Parameters](#)\
   2.10. [Delegating or Forwarding](#)\
   2.11. [Defining Class-Level Readers and Writers](#)
3. [Working with Dynamic Features](#)\
   3.1. [Evaluating Code Dynamically](#)\
   3.2. [Retrieving a Constant by Name](#)\
   3.3. [Retrieving a Class by Name](#)\
   3.4. [Using define_method](#)\
   3.5. [Obtaining Lists of Defined Entities](#)\
   3.6. [Removing Definitions](#)\
   3.7. [Handling References to Nonexistent Constants](#)\
   3.8. [Handling Calls to Nonexistent Methods](#)\
   3.9. [Improved Security with taint](#)\
   3.10. [Defining Finalizers for Objects](#)
4. [Program Introspection](#)\
   4.1. [Traversing the Object Space](#)\
   4.2. [Examining the Call Stack](#)\
   4.3. [Tracking Changes to a Class or Object Definition](#)

## Everyday OOP Tasks

### Using Multiple Constructors

You can implement multiple constructors with the help of additional class methods that return new objects.

```ruby

class ColoredRectangle
  def initialize(r, g, b, s1, s2)
    @r, @g, @b, @s1, @s2 = r, g, b, s1, s2
  end

  def self.white_rect(s1, s2)
    new(0xff, 0xff, 0xff, s1, s2)
  end

  def self.gray_rect(s1, s2)
    new(0x88, 0x88, 0x88, s1, s2)
  end

  def self.colored_square(r, g, b, s)
    new(r, g, b, s, s)
  end

  def self.red_square(s)
    new(0xff, 0, 0, s, s)
  end

  def inspect
    "#@r #@g #@b #@s1 #@s2"
  end
end

a = ColoredRectangle.new(0x88, 0xaa, 0xff, 20, 30)
b = ColoredRectangle.white_rect(15, 25)
c = ColoredRectangle.red_square(40)
```


### Creating Instance Attributes

An instance attribute in Ruby is always prefixed by an `@` sign. It is like an ordinary variable
in that it springs into existence when it is first assigned.

In OO languages, we frequently create methods that access attributes to avoid issues of data 
hiding. We want to have control over how the internals of an object are accessed from the outside.
Typically we use setter and getter methods for this purpose.

Of course, it is possible to create these functions "by hand":

```ruby
class Person
  def name
    @name
  end
  
  def name=(x)
    @name = x
  end
  
  def age
    @age
  end
  
  # ...
end
```

However, Ruby gives us a shorthand for creating these methods. The `attr` method takes a symbol
as a parameter and creates the associated attribute. It also creates a getter of the same name, and if
the optional second parameter is **true**, it creates a setter as well:

```ruby
class Person
  attr :name, true  # Create @name, name, name=
  attr :age         # Create @age, age
end
```

The related methods `attr_reader`, `attr_writer`, and `attr_accessor` take any number of symbols
as parameters. The first creates only getters; the second creates only setters; the third creates
both.


### Using more Elaborate Constructors

As objects grow more complex, they accumulate more attributes that must be initialized when an 
object is created. The corresponding constructor can be long and cumbersome, forcing us to count 
parameters and wrap the line past the margin.

One way to deal with this complexity is to pass in a block that accepts the new object to the
`initialize` method. We can then evaluate the block to initialize the object.

```ruby
class PersonalComputer
  attr_accessor :manufacturer,
                :model, :processor, :clock,
                :ram, :disk, :monitor,
                :colors, :vres, :hres, :net

  def initialize
    yield self if block_given?
  end
end

desktop = PersonalComputer.new do |pc|
  pc.manufacturer = "Acme"
  pc.model = "THX-1138"
  pc.processor = "Z1"
  pc.clock = 9.6 
  pc.ram = 512
  pc.disk = 20 
  pc.monitor = 30 
  pc.colors = 16777216 
  pc.vres = 1600 
  pc.hres = 2000 
  pc.net = "OC-768"
end
```

> Note! We are using **accessors** for our attributes so that we can assign values to them.
> Additionally, we could perform any arbitrary logic we wanted inside the body of this block.
> For example, we could derive certain fields from others by computation.

What if you didn't really want an object to have accessors for each of the attributes? In that
case, we could use `instance_eval` instead and make the setter methods **protected**. This could
prevent "accidental" assignment of an attribute from outside the object:

```ruby
class Library
  attr_reader :shelves

  def initialize(&block)
    instance_eval(&block)
  end
  
  protected
  
  attr_writer :shelves
end

branch = Library.new do
  self.shelves = 10
end

branch.shelves = 20
# NoMethodError: protected method 'shelves=' called
branch.shelves    # 10
```

> Even when you are using `instance_eval`, explicit calls to setters on **self** are still required.
> A setter method always takes an explicit receiver to distinguish the method call from an ordinary
> assignment to a local variable.


### Creating Class-Level Attributes and Methods

We can define class methods of our own by putting `self.` in front of the method name within a class.

```ruby
class SoundPlayer
  MAX_SAMPLE = 192
  
  def self.detect_hardware
    # ...
  end
  
  def play
    # ...
  end
end
```

Notice there is another way to declare this class method:

```ruby
def SoundPlayer.detect_hardware
  # ...
end
```

The only difference relates to constants declared in the class. When the class method is declared
outside its class declaration, these constants are **not** in scope.

> There are class variables as well as class methods. These begin with a double `@` sign, and
> their scope is the class rather than any instance of the class.


### Inheriting from a Superclass

> Calling `super` in a child class method simply calls the corresponding method in the parent class.

- Every attribute/method of the parent class is reflected in the child
- The child can have additional attributes and methods. This is why the creation of a subclass is often
  referred to as "extending a superclass".
- The child can override or redefine any of the attributes and methods of its parent.

> How a method is resolved?
> – You don't know, and you don't care. If you invoke a method on a child class object, the method
> for that class will be called if it exists. If it doesn't, the method in the superclass will be called
> and so on.

> **Every** class (except **BasicObject**) has a superclass.

If you specifically want to call a superclass method, but you don't happen to be in the corresponding
method, you can always create and **alias** in the _subclass_ before you do anything with it:

```ruby
class Student < Person # reopening class
  # Assuming Person has a `say_hello` method
  alias :say_hi :say_hello
  
  def say_hello
    puts "Hi, there."
  end
  
  def formal_greeting
    # Say hello the way my superclass would
    say_hi
  end
end
```


### Testing Classes of Objects

The `class` method always returns the class of an object:

```ruby
s = "Hello"
sc = s.class    # String
```

> Don't be misled into thinking that the thing returned by `class` or `type` is a string representing
> the class. It is an actual instance of the class `Class`. Therefore, if we wanted, we could call a
> class method of the target type as though it were an instance method of **Class** (which it is).
> ```ruby
> s2 = "some string"
> var = s2.class            # String
> my_str = var.new("Hi..")  # A new string
> ```

To check whether an object belongs to a given class, use `instance_of?`:

```ruby
puts 5.instance_of?(Fixnum)        # true
puts "XYZZY".instance_of?(Fixnum)  # false
```

But if you want to take **_inheritance_** relationship into account, the `kind_of?` takes this issue
into account. A synonym is `is_a?`.

```ruby
n = 987654321
flag1 = n.instance_of? Bignum   # true
flag2 = n.is_a? Integer         # true
flag3 = n.is_a? Numeric         # true
flag4 = n.is_a? Object          # true
```

> **[NB]** Any module that is mixed in by a class maintains the is-a relationship with the instances.
> For example, the **Array** class mixes in **Enumerable**; this menas that any array is a kind of
> enumerable entity.

```ruby
x = [1, 2, 3]
flag5 = x.kind_of? Enumerable   # true
flag6 = x.is_a? Enumerable      # true 
```

We can also use the numeric relational operators in a fairly intuitive way to compare one class to
another. We say "intuitive" because the less-than operator is used to denote inheritance from a 
superclass:

```ruby
flag1 = Integer < Numeric     # true
flag2 = Object == Array       # false
flag4 = IO >= File            # true
```

Every class has the `===` operator defined.
The expression `**class** === **instance**` will be **true** if the instance belongs to the class.
The relationship operator is usually known as the case equality operator because it is used implicitly
in a `case` statement.

If you want to get the superclass of an object or class, you can use the instance method `superclass`.


### Testing Equality of Objects

The most basic comparison is the `equal?` method (which comes from **BasicObject**). It returns
true if its receiver and parameter have the **same object ID**.

The most common test for equality is `==`, which test the values of its receiver and argument.

Next, on the scale of abstraction is the method `eql?`, which is implemented in the **Kernel** 
module, which is mixed into **Object**). Like the `==` operator, `eql?` compares its receiver and
its argument, but is slightly stricter. 
For example, different numeric objects will be coerced into a common type when compared using `==`,
but objects of different types will never test equal using `eql?`:

```ruby
flag1 = (1 == 1.0)    # true
flag2 = 1.eql?(1.0)   # false
```

> The `eql?` method exists for one reason: It is used to compare the values of hash keys. If you
> want to override Ruby's default behavior when using your objects as hash keys, you'll need to
> override the methods `eql?` and `hash` for those objects.

The `===` method is used to compare the target in a case statement against each of the selectors.
This rule allows Ruby case statements to be intuitive in practice. For example you can switch based
on the class of an object:

```ruby
case an_object
when String
  puts "It's a string"
when Numeric
  puts "It's a number"
else
  puts "It's something else entirely."
end
```

This works because class **Module** implements `===` to test whether its parameter is an instance of
its receiver (or the receiver's parents).

Finally, Ruby implements the match operator `=~`. Conventionally, this is used by strings and regular
expressions to implement pattern matching. However, if you find a use for it in other classes, you're
free to overload it.

The equality tests `==` and `=~` also have negated forms, `!=` and `!~`, respectively. These are 
implemented internally by reversing the sense of the non-negated form. This means if you implement,
say, the method `==`, you also get the method `!=` for free.


### Controlling Access to Methods

The `private` method. You can use it in 2 different ways. If in the body of a class or method definition
you call `private` with no parameters, subsequent methods will be made private to that class or module.
Alternatively, you can pass a list of method names to `private` and these named methods will be made
private.

> Because the `attr` family of statements effectively just defines methods, attributes are affected
> by access control statements such as `private`.

The `protected` access modified is less restrictive. Protected methods can be accessed only by instances
of the defining class and its subclasses.

> As a final twist, normal methods defined outside a class or module definition (that is, the methods
> defined at the top level) are made private by default. Because they are defined in class **Object**,
> they are globally available, but they cannot be called with a receiver.


### Copying an Object

The Ruby built-in methods `Object#clone` and `#dup` produce copies of their receiver.
They differ in the amount of context about the object they copy. The `dup` method copies just
the object's content, whereas `clone` also preserves things such as singleton classes associated
with the object.

```ruby
s1 = "cat"

def s1.upcase
  "CaT"
end

s1_dup = s1.dup
s1_clone = s1.clone
s1                    # "cat"
s1_dup.upcase         # "CAT" (singleton method not copied)
s1_clone.upcase       # "CaT" (uses singleton method)
```

Both `dup` and `clone` are _**shallow**_ copies: They copy the immediate contents of their receiver
only. If the receiver contains references to other objects, those objects aren't in turn copied; the
duplicate simply holds references to them. 

```ruby
# The object arr2 is a copy of arr1, so changing the entire elements such as arr2[2] has no effect
# on arr1. However, both the original array and the duplicate contain reference to the same String
# object, so changing its contents via arr2 also affects the value referenced by arr1:
arr1 = [1, "flipper", 3]
arr2 = arr1.dup

arr2[2] = 99
arr2[1][2] = 'a'

arr1      # [1, "flapper", 3]
arr2      # [1, "flapper", 99]
```

If you want to make a **_deep_** copy, where the entire object tree rooted in on object is copied
to create the second object. This way, there is guaranteed to be no interaction between the two. Ruby
provides no built-in method to perform a deep copy, but there are a couple of techniques you can
use to implement one.

The pure way is to have your classes implement a `deep_copy` method. As part of its processing, this
method calls `deep_copy` recursively on all the objects referenced by the receiver. You then add a 
`deep_copy` method to all the Ruby built-in classes that you use.

There's a quicker way using the **Marshal** module. If you use marshaling to dump and object into
a string and then load it back into a new object, that new object will be a deep copy of the original.

```ruby
arr1 = [1, "flipper", 3]
arr2 = Marshal.load(Marshal.dump(arr1))
```


### Using `initialize_copy`

When you copy an object with `dup` or `clone`, the constructor is bypassed. All the state information
is copied.

```ruby
class Document
  attr_reader :timestamp
  
  def initialize(title, text)
    @title, @text = title, text
    @timestamp = Time.now
  end
end

doc1 = Document.new("Blah", File.read("somefile"))
sleep 300
doc2 = doc1.clone

doc1.timestamp == doc2.timestamp  # true
```

Defining an `initialize_copy` makes capturing the time that the copy operation happens possible. This
method is called when an object is copied. It is analogous to `initialize`, giving us complete control
over the object's state.

```ruby
class Document
  def initialize_copy(other)
    @timestamp = Time.now
  end
end

doc3 = Document.new("Yada", File.read("other"))
sleep 300
do4 = doc3.clone

doc3.timestamp == doc4.timestamp  # false
```

> `initialize_copy` is called after the information is copied. As a matter of fact, an empty `initialize_copy`
> would behave just as if the method were not there at all.


### Understanding `allocate`

If you want to create an object without calling its constructor, for example you want to have an 
object whose state is determined entirely by its accessors, then it isn't necessary to call `new`
(which calls `initialize`) unless you really want to. 

The `allocate` makes this easier. It returns a "blank" object of the proper class, yet uninitialized.


### Working with Modules

There are two basic reasons to use modules in Ruby. 
The first is simply **_namespace_** management; the second reason is more interesting: We can use
a module as a mixin. A mixin is like a specialized implementation of multiple inheritance in which
only the interface portion is inherited.

> A module isn't a class, so it can **NOT** have instances, and an instance method can't be called
> without a receiver.
> A module can actually have instance methods once it is included in a class – then they become part
> of the class.

```ruby
module MyMod
  def method_1
    puts "This is method 1"
  end
end

class MyClass
  include MyMod
end

x = MyClass.new
x.method_1    # This is method 1
```

The `include` at the top level, in that case, mixes in the module into **Object**.

But what happens to the module methods, if there are any? Are they included as class methods?
They are **NOT**.
41414140101401401101000
000> 000000000000000.000.1000000000There's a hooc called `included` that we can override. It is called with a parameter, which is
> the "destination" class or module (into which the module is being included). 

```ruby
module MyMod
  def self.included(klass)
    def klass.module_method
      puts "Module (class) method"
    end
  end
  
  def method_1
    puts "Method 1"
  end
end

class MyClass
  include MyMod
  
  def self.class_method
    puts "Class method"
  end
  
  def method_2
    puts "Method 2"
  end
end

x = MyClass.new

MyClass.class_method    # Class  method
x.method_1              # Method 1
MyClass.module_method   # Module (class) method
x.method_2              # Method 2
```

`included` is a hook that is called when an `include` happens. 

Also note that within the `included` method definition there is yet another definition. This looks
unusual, but it works because the inner method definition is a singleton method (class level or 
module level). An attempt to define an instance method in the same way would result in an error.

It is also possible to mix in the instance methods of a module as class method using `include` or
`extend`.

```ruby
module MyMod
  def meth3
    puts "Module instance method meth3"
    puts "can become a class method."
  end
end

class MyClass   
  class << self   # Here, self is MyClass 
    include MyMod
  end
end

MyClass.meth3    # hits the 2 puts
```

The last example can be simplified with `extend`:

```ruby
class MyClass
  extend MyMod
end
```

Although it is certainly possible for modules to have their own instance data, it usually isn't
done. However, if you find find a need for this capability, there is nothing stopping you from
using it.

> It is possible to define methods in your **class** that will be called by the **mixin**. This is
> a powerful technique.

The classic example is mixing in the `Comparable` module and defining a `<=>` method. Because the
mixed-in methods can call the comparison method, we now have such operators as `<`, `>`, `<=` and so on.


### Transforming or Converting Objects

Methods such as `puts` and contexts such as #{...} interpolation in strings all expect to receive a
**String** as a parameter. If they don't, they ask the object they did receive to convert itself to a
**String** by sending it a `to_s` message. This is where you can specify how your object will appear
when displayed.

Other methods (such as the **String** concatenation operator `+`) are more picky; they expect you
to pass in something that is really pretty close to a **String**. In this case, Matz decided not to
have the interpreter call `to_s` to convert non-string arguments because he felt this would lead to
too many errors. Instead, the interpreter invokes a stricter method, `to_str`. Of the built-in classes,
only **String** and **Exception** implement `to_str`, and only **String**, **Regexp** and **Marshal**
call it.

An analogous situation holds for arrays. The method `to_a` is called to convert an object to an
array representation, and `to_ary` is called when an array is expected.

Here's also an unrealistic example in which a string is converted to an array of strings:

```ruby
class String
  def to_ary
    self.split ""
  end
end

str = "UFO"
a, b, c = str   # ["U", "F", "O"]
```


### Creating Data-Only Classes (Structs)

Sometimes you need you need to group together a bunch of related data. Initially, it can be easy to
simply use an array or a hash. That approach is brittle, and makes changes or adding accessor methods
difficult. You could solve the problem by defining a class, but it's tedious and a fair amount of
repetition is in there. 

That's why the built-in class **Struct** comes in handy. In the same way that convenience methods 
such as `attr_accessor` define methods to access attributes, class **Struct** defines classes that
contain attributes. These classes are structure templates:

```ruby
Address = Struct.new("Address", :street, :city, :state)
books = Address.new("411 Elm St", "Dallas", "TX")
```

> When we create a new structure template by calling `Struct.new`, we may pass a string with the class name
> as the first argument. If we do, a new class is created _within class_ **Struct** _itself_, with the
> name passed in as the first parameter and the attributes given as the rest of the parameters. This
> means that if we wanted, we could access this newly created class within the namespace of class **Struct**:
> 
> ```ruby
> Struct.new "Address", :street, :city, :state
> books = Struct::Address.new "411 Elm St", "Dallas", "TX"
> ```

When creating a **Struct** class, additional methods can be defined for the class by simply providing
a block to `Struct.new`. The block will be evaluated as if it were the class body, much like any
other class definition.

When instantiating a Struct, you don't have to assign values to all the attributes in the constructor.
Those that you omit will be initialized to **nil**.


### Freezing Objects

Sometimes we want to prevent an object from being changed. The `freeze` method (in **Object**)
allows us to do this, effectively turning an object into a constant.

> Freezing strings is handled as a special case: The interpreter will create a single frozen string
> object and return it for every instance of the frozen string. This can reduce memory usage if, for
> example, a particular string will be returned from a method that is called many times:
> ```ruby
> str1 = "Woozle".freeze
> str2 = "Woozle".freeze
>
> str1.object_id == str2.object_id  # true
> ```

Although freezing prevents modification, it operates on an object reference, not on a variable!
This means that any operation resulting in a new object will work.

```ruby
str = "counter-"
str.freeze
str += "intuitive"  # "counter-intuitive"

arr = [8, 6, 7]
arr.freeze
arr += [5, 3, 0, 9]   # [8, 6, 7, 5, 3, 0, 9]
```

This happens because `a += x` is semantically equivalent to `a = a + x`. The expression `a + x`
is evaluated to a new object, which is then assigned to `a`. The object isn't changed, but the 
variable now refers to a new object. 


### Using `tap` in Method Chaining

The `tap` method runs a block with access to the value of an expression in 
the middle of other operations. Once use of `tap` can be to print intermediate
values while they are being processed, because the block is passed the object
that `tap` is called on:

```ruby
a = [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 2]
p.sort.uniq.tap{ |x| p x }.map{ |x| x**2 + 2*x + 7}
# [1, 2, 3, 4, 5]
# [10, 15, 22, 31, 42]
```

Providing this sort of access can be helpful, but the real power of tap comes 
from its ability to change the object inside the block. This allows code to alter
an object and still return the original object, rather than the result of the 
last operation:

```ruby
def feed(woozle)
  woozle.tap do |w|
    w.stomach << Steak.new
  end
end
```

Without `tap`, our `feed` method would return the stomach that now contains
a steak. Instead it returns the newly fed woozle.

> This technique is highly useful inside class methods that construct an object, 
> call methods on the object, and then return the object. It is also handly when
> implementing methods that are intended to be chained together.


## More Advanced Techniques

### Sending an Explicit Message to an Object

Every time you invoke a method, you're sending a message to an object. Most of
the time, these messages are hard-coded as in a static language, but they need
not always be. The `send` method will allow us to use a **Symbol** to represent
a method name.

```ruby
class Array
  def map_by(sym)
    self.map{|x| x.send(sym)}
  end
end

array.map_by(:name)
```

This particular example is not really practical because we can simply call
`map(&:name)` and get the same result, but it illustrates the `send` method well.

There's also a synonym `__send__` which does the exact same thing. It is given
this peculiar name, because `send` is a name that might be used as a user-defined
method name.

> One issue that some coders have with `send` is that it allows circumvention of
> Ruby's privacy model (in the sense that private methods may be called indirectly
> by sending the object a string or symbol). If you are more comfortable "protecting
> yourself" against doing this accidentally, you can use the `public_send` method instead.


### Specializing an Individual Object

In most OO languages, all objects of a particular class share the same behavior. The class acts a 
template, producing an object with the same interface each time a constructor is called.

Ruby acts the same way, but that's not the end of the story. Once you have a Ruby object, you can change
its behavior "on the fly". Effectively, you're giving that object a **private, anonymous** subclass: All
the methods of the original class are available, but you've added additional behavior for just that object.
Because this behavior is private to the associated object, it can only occur once. A thing occuring only
once is called a _"singleton"_, so we sometimes refer to singleton methods and classes.

```ruby
a = "hello"
b = "goodbye"

def b.upcase # create single method
  gsub(/(.)(.)/) { $1.upcase + $2 }
end

puts a.upcase   # HELLO
puts b.upcase   # Go0dBye
```

> Adding a singleton method to an object creates a _singleton_ class for that object if one does **not**
> already exist. This singleton class's parent will be the object's **original** class.

If you want to add multiple methods to an object, you can create the singleton class directly:

```ruby
b = "goodbye"

class << b
  def upcase # create single method 
    gsub(/(.)(.)/) { $1.upcase + $2 }
  end
  
  def upcase!
    gsub!(/(.)(.)/) { $1.upcase + $2 }
  end 
end

puts b.upcase # GoOdBye 
puts b        # goodbye 
b.upcase!
puts b        # GoOdBye
```

Within the body of a class definition, `self` is the class you're defining, so creating a singleton
based on it modifies the class's class. At the simplest level, this means that instance methods in the
singleton class are class methods externally:

```ruby
class TheClass
  class << self 
    def hello
      puts "hi"
    end
  end
end

# invoke a class method
TheClass.hello    # hi
```

Another common use of this technique is to define class-level helper functions, which we can then access 
in the rest of the class definition. As an example, we want to define serveral accessor functions that 
always convert their results to a string. 

```ruby
class MyClass
  class << self 
    def accessor_string(*names)
      names.each do |name|
        class_eval <<-EOF
          def #{name}
            @#{name}.to_s
          end
        EOF
      end
    end
  end

  def initialize
    @a = [1, 2, 3]
    @b = Time.now
  end
  
  accessor_string :a, :b
end

o = MyClass.new
puts o.a  # 123
puts o.b  # 2014-07-26 00:45:12 -0700
```


### Nesting Classes and Modules

It is possible to **nest** classes and modules arbitrarily. 

It's conceivable that you might want to create a nested class simply because the outside world doesn't
need that class or shouldn't access it. In other words, you can create classes that are subject to the 
principle at a lower level.

```ruby
class BugTrackingSystem
  class Bug
    # ...
  end
end


# Nothing out here knows about Bug.
```

You can nest a class within a module, a module within a class, and so on.


### Creating Parametric Classes

Suppose we wanted to create multiple classes that differed only in the initial values of the class-level
variables.

```ruby
class IntelligentLife    # Wrong way to do this.
  @@home_planet = nil 
  
  def IntelligentLife.home_planet
    @@home_planet
  end
  
  def IntelligentLife.home_planet=(x)
    @@home_planet = x
  end
end

class Terran < IntelligentLife
  @@home_planet = "Earth"
end

class Martian < IntelligentLife
  @@home_planet = "Mars"
end
```

However, this won't work. If we call `Terran.home_planet` we expect a result of "Earth" – but we get "Mars"!
Why would this happen? The answer is that..

> Class variables are **not** truly class variables; they belong not to the class but to the **_entire inheritance_**
> hierarchy. The class variables aren't copied from the parent class but are **SHARED** with the parent (and thus
> with the "siblings" classes).

So the best way to solve this problem is:

```ruby
class IntelligentLife
  class << self 
    attr_accessor :home_planet
  end
  
  # ...
end

class Terran < IntelligentLife
  self.home_planet = "Earth"
end

class Martian < IntelligentLife
  self.home_planet = "Mars"
end

puts Terran.home_planet   # Earth
puts Martian.home_planet  # Mars
```

Here, we open up the singleton class and define an accessor called `home_planet`. The two child classes
call their own accessors and set the variable. These accessors work strictly on a per-class basis now.

As a small enhancement, let's also add a `private` call in the singleton class:

`private :home_planet=`

Making the writer private will prevent any code outside the hierarchy from changing this value. As always,
using `private` is an **"advisory"** protection and is easily bypassed by the programmer who wants to. 
Making a method private at least tells us we are not meant to call that method in this particular context.


### Storing Code as **Proc** Objects

The built-in class **Proc** represents a Ruby block as an object. **Proc** objects, like blocks, are
closures and therefore carry around the context where they were defined. The `proc` method is a shorthand
alias for `Proc.new`.

```ruby
local = 12
myproc = Proc.new { |a| puts "Param is #{a}, local is #{local}"}
myproc.call(99)   # Param is 99, local is 12
```

**Proc** objects are also created automatically by Ruby when a method defined with a trailing & parameter
is called with a block:

```ruby
def take_block(x, &block)
  puts block.class
  x.times { |i| block[i, i*i] }
end

take_block(3) { |n, s| puts "#{n} squared is #{s}" }

# Proc
# 0 squared is 0
# 1 squared is 1
# 2 squared is 4
```

This example also shows the use of brackets `[]` as an alias for the `call` method.

If you have a **Proc** object, you can pass it to a method that's expecting a block, preceding its name with
an `&`, as shown here:

```ruby
myproc = proc { |n| print n, "..." }
(1..3).each(&myproc)    # 1.. 2.. 3..
```

Although it can certainly be useful to pass a **Proc** to a method, calling `return` from inside the
**Proc** returns for the **_entire_** method. A special type of **Proc** object, called a **_lambda_**
returns only from the block:

```ruby
def greet(&block)
  block.call
  "Good morning, everyone"
end

philippe_proc = Proc.new { return "Too soon, Philippe!" }
philippe_lambda = lambda { return "Too soon, Philippe!" }

p greet(philippe_proc)    # Too soon, Philippe!
p greet(philippe_lambda)  # Good morning, everyone.
```

> In addition to the keyword `lambda`, the `->` notation also creates lambdas. Just keep in mind that
`->` (sometimes called "stabby proc" or "stabby lambda") puts block arguments outside the curly braces:

```ruby
non_stabby_lambda = lambda { |king| greet(king) }
stabby_lambda     = -> (king) { stab(king) }
```


### Storing Code as **Method** Objects

Ruby also lets you turn a method into an object directly using `Object#method`. The `method` method returns
a **Method** object, which is a closure that is bound to the object it was created from:

```ruby
str = "cat"
meth = str.method(:length)

a = meth.call # 3 length of cat
str << "erpillar"
b = meth.call # 11 length of caterpillar

str = "dog"
c = meth.call  # 11 length of caterpillar
```

Note the final `call`. The variable `str` refers to a new object ("dog") now, but `meth` is still bound to
the old object.

To get a method that can be used with any instance of a particular class, you can use `instance_method`
to create **UnboundMethod** objects. Before calling an **UnboundMethod** object, you must first bind it to a 
particular object. This act of binding produces a **Method** object, which you call normally:

```ruby
umeth = String.instance_method(:length)

m1 = umeth.bind("cat")
m1.call                 # 3

m2 = umeth.bind("caterpillar")
m2.call                 # 11
```


### Using Symbols as Blocks

> When a parameter is prefixed with an ampersand `&`, it is treated by Ruby as a **block**  parameter.
> As shown earlier, it is possible to create a **Proc** object, assign it to a variable, and then use
> that **Proc** as the block for a method that takes a block.

However, it is possible to call methods that require blocks but only pass them a symbol prefixed by
an ampersand. Why is that possible? The answer lies in the `to_proc` method. 

A non-obvious side effect of providing a block parameter as an argument is that if the argument is not
a **Proc**, Ruby will attempt to convert it into one by calling `to_proc` on it.

Some clever Ruby developers realized that this could be leveraged to simplify their calls to `map`, and
they defined the `to_proc` method on the **Symbol** class. The implementation looks something like this.

```ruby
class Symbol
  def to_proc
    Proc.new { |obj| obj.send(self) }
  end
end

# Which allows map to be invoked like this:
%w[A B C].map(&:chr)    # [65, 66, 67]
```


### How Module Inclusion Works

When a module is included into a class, Ruby in effect creates a proxy class as the immediate ancestor
of that class. Any methods in an included module are "masked" by any methods that appear in the class.

```ruby
module MyMod
  def meth
    "from module"
  end
end

class ParentClass
  def meth
    "from parent"
  end
end

class ChildClass < ParentClass
  def meth
    "from child"
  end
  
  include MyMod
end

x = ChildClass.new
p x.meth    # from child
```

This is just like a regular inheritance relationship: Anything the child redefines is the new current
definition. This is true regardless of whether the `include` is done before or after the redefinition.

```ruby
# MyMod and ParentClass unchanged
class ChildClass < ParentClass
  include MyMod
  
  def meth
    "from child: super = #{super}"
  end
end

x = ChildClass.new
p x.method    # from child: super = from module
```

As you can see, **MyMod** is the new parent of **ChildClass**.

```ruby
module MyMod
  def meth
    "from module: super #{super}"
  end
end

# ParentClass is unchanged
class ChildClass < ParentClass
  include MyMod
  
  def meth
    "from child: super #{super}"
  end
end

x = ChildClass.new
p x.method  # from child: super from module: super from parent
```

Modules have one more trick up their sleeve, though, in the form of the `prepend` method. It allows
a module method to be inserted beneath the method of the including class.

```ruby
# MyMod and ParentClass unchanged
class ChildClass < ParentClass
  prepend MyMod
  
  def meth
    "from child: suoer #{super}"
  end
end

x = ChildClass.new
p x.meth   # from module: super from child: super from parent
```

This feature of Ruby allows modules to alter the behavior of methods even when the method in the child
class does not call `super`.

Whether included or prepended, the `meth` from **MyMod** can call `super` only because there actually
is a `meth` in the superclass (that is, in at least one ancestor).


### Detecting Default Parameters

The following question was once asked by Ian Macdonald on the Ruby mailing list: "How can I detect
whether a parameter was specified by the caller, or the default was taken?". This is an interesting
question; not something you would use every day, but still interesting.

```ruby
def meth(a, b=(flag=true; 345))
  puts "b is #{b} and flag is #{flag.inspect}"
end

meth(123)       # b is 345 and flag is true
meth(123, 345)  # b is 345 and flag is nil
meth(123, 456)  # b is 456 and flag is nil
```

> This trick works even if the caller explicitly supplies what happens to be the default value. The 
> trick is obvious when you see it: The parenthesized expression sets a local variable called `flag` but
> then returns the default value `345`.


### Delegating or Forwarding

The **SimpleDelegator** class can be useful when the object delegated to can change over the lifespan
of the receiving object. The `__setobj__` method is used to select the object to which you're delegating.

The **DelegateClass** top-level method takes a class (to be delegated to) as a parameter. It then 
creates a new class from which we can inherit. Here's an example of creating our own **Queue** class
that delegates to an **Array** object:

```ruby
require 'delegate'

class MyQueue < DelegateClass(Array)
  def initialize(arg=[])
    super(arg)
  end
  
  alias_method :enqueue, :push
  alias_method :dequeue, :shift
end

mq = MyQueue.new
mq.enqueue(123)
mq.enqueue(234)

p mq.dequeue    # 123
p mq.dequeue    # 234
```

It is also possible to inherit from **Delegator** and implement a `__getobj__` method; this is the way
**SimpleDelegator** is implemented, and it offers more control over the delegation.

However, if you want more control, you should probably be doing per-method delegation rather than
per-class anyway. The `forwardable` library enables you to do this. 

```ruby
require 'forwardable'

class MyQueue
  extend Forwardable
  
  def initialize(obj=[])
    @queue = obj  # delegate to this object
  end
  
  def_delegator :@queue, :push, :enqueue
  def_delegator :@queue, :shift, :dequeue
  
  def_delegators :@queue, :clear, :empty?, :length, :size, :<<
  
  # Any additional stuff
end
```

This example shows that the `def_delegator` method associates a method call (for example, `enqueue`)
with a delegated object **@queue** and the correct method to call on that object (`push`). In other
words, when we call `enqueue` on a **MyQueue** object, we delegate that by making a push call no our 
object `@queue` (which is usually an array).

We say `:@queue`, rather than `:queue` or `@queue` simply because of the way the **Forwardable**
class is written.

Sometimes we want to pass methods through to the delegate object by using the same method name. The
`def_delegators` method allows us to specify an unlimited number of these. For example, as shown in
the preceding code example, invoking `length` on a **MyQueue** object will in turn call `length` on `@queue`.

Unlike the first example in this chapter, the other methods on the delegate object are simply not 
supported. This can be a good thing. For example, you don't want to invoke `[]` or `[]=` on a queue;
if you do, you're not using it as a queue anymore.

> Notice that the previous code allows the caller to pass an object into the constructor (to be 
> used as the delegate object). In the spirit of duck-typing, this means that we can choose the
> kind of object we want to delegate to – as long as it supports the set of methods that we 
> reference in the code.

```ruby
require 'thread'

q1 = MyQueue.new                    # use an array
q2 = MyQueue.new(my_array)          # use one specific array
q3 = MyQueue.new(Queue.new)         # use a Queue
q4 = MyQueue.new(SizedQueue.new)    # use a SizedQueue
```

There's also a **SingleForwardable** class that operates on an instance rather than on an entire 
class. This is useful if you want just one instance of a class to delegate to another object, while
all other instances continue not to delegate.

One final option is manual delegation. Ruby makes it extremely straightforward to simply wrap one object
in another, which is another way to implement our queue:

```ruby
class MyQueue
  def initialize(obj=[])
    @queue = obj
  end
  
  def enqueue(arg)
    @queue.push(arg)
  end
  
  # ...
end
```


### Defining Class-Level Readers and Writers

Ruby has no facility for creating these automatically. However, we could create something similar on
our own very simply. Just open the singleton class and use the ordinary `attr` family of methods.

The resulting instance variables in the singleton class will be class instance variables. These are 
often better for our purposes than class variables because they are strictly "per class" and are not
shared up and down the hierarchy.

```ruby
class MyClass
  @alpha = 123
  
  class << self 
    attr_reader :alpha
    attr_writer :beta
    attr_accessor :gamma
  end
end
```


## Working with Dynamic Features

### Evaluating Code Dynamically

The global function `eval` compiles and executes a string that contains a fragment of Ruby code.
This is a powerful (albeit extremely dangerous) mechanism, because it allows you to build up code
to be executed at runtime. For example, the following code reads in line of the form "name = expression".
It then evaluates each expression and stores the result in a hash indexed by the corresponding variable
name:

```ruby
parameters = {}

ARGF.each do |line|
  name, expr = line.split(/\s*=\s*/, 2)
  parameters[name] = eval expr
end
```

Ruby has 3 other methods that evaluate code "on the fly": `class_eval`, `module_eval` and `instance_eval`.
The first 2 are synonyms, and all 3 do effectively the same thing; they evaluate a string or a block, but
while doing so they change the value of `self` to their own receiver. Perhaps the most common use of
`class_eval` allows you to add methods to a class when all you have is a reference to the class.

The `eval` method also makes it possible to evaluate local variables in a context outside their scope.
We don't advise doing this lightly, but it's nice to have the capability. 

> Ruby associates local variables with blocks, with high-level definition constructs (class, module, and
> other definitions), and with top-level of your program (the code outside any definition constructs). 
> Associated with each of these scopes is the binding of variables, along with other housekeeping details.


### Retrieving a Constant by Name

The `const_get` method retrieves the value of a constant (by name) from the module or class to which
it belongs:

```ruby
str = "PI"
Math.const_get(str)   # Evaluates to Math::PI
```

This is a way of avoid the use of `eval`, which is both dangerous and considered inelegant. It is
also computationally cheaper, and it's safer. Other similar methods are `instance_variable_set`, 
`instance_variable_get`, and `define_method`.


### Retrieving a Class by Name

Classes in Ruby are normally named as constants in the "global" namespace – that is, members of **Object**. That
means the proper way is with `const_get`, which we just saw:

```ruby
classname = "Array"
klass = Object.const_get(classname)
x = klass.new(4, 1)   # [1, 1, 1, 1]
```

If the constant is inside a namespace, just provide a string that with namespaces delimited by two colons – "Alpha::Beta::Gamma::FOOBAR"


### Using `define_method`

Other than `def`, `define_method` is the only normal way to add a method to a class or object; the latter, however, enables you
to do it at runtime.

> Of course, essentially everything in Ruby happens at runtime.

However, within a method body or similar place, we can't just reopen a class. In such a case, we use `define_method`. It takes a symbol
(for the name of the method) and a block (for the body of the method).

```ruby
if today =~ /Saturday|Sunday/
  define_method(:activity) { puts "Playing" }
else
  define_method(:activity) { puts "Working" }
end

activity
```

Note, however, that `define_method` is private. This means that calling it from inside a class definition or method will work just fine, as 
shown here:

```ruby
class MyClass
  define_method(:body_method) { puts "The class body." }
  
  def self.new_method(name, &block)
    define_method(name, &block)
  end
end

MyClass.new_method(:class_method) { puts "A class method." }

x = MyClass.new
x.body_method   # Prints "The class body."
x.class_method  # Prints "A class method."
```

> `define_method` takes a block, and a block in Ruby is a closure. This means that, unlikely an ordinary method definition, we are capturing context
> when we define the method. The point is that the new method can access variables in the original scope of the block, even if that scope "goes away"
> and is otherwise inaccessible.


### Obtaining Lists of Defined Entities

The **Module** module has a method `constants` that returns an array of all the constants in the system (including class and
module names). The `nesting` method returns an array of all the modules nested at the **_current_** location in the code.

The instance method `ancestors` returns an array of all the ancestors of the specified class or module.

The `class_variables` method returns a list of all class variables in the given class and its superclasses. The `included_modules`
method lists the modules included in a class.

The **Class** methods `instance_methods` and `public_instance_methods` are synonyms; they return a list of the public instance
methods for a class. The methods `private_instance_methods` and `protected_instance_methods` behave as expected. Any of
these can take a **Boolean** parameter, which defaults to **true**; if it is set to `false`, superclasses will not
be searched, thus resulting in a smaller list.

The **Object** class has a number of similar methods that operate on instances. Calling `methods` will return a list of all
methods that can be invoked on that object. Calling `public_methods`, `private_methods`, `protected_methods` and `singleton_methods`
all take a boolean parameter and they return the methods you would expect them to return.


### Removing Definitions

The dynamic nature of Ruby means that pretty much anything that can be defined can also be undefined. Once conceivable
reason to do this is to decouple pieces of code that are in the same scope by getting rid of variables after they have 
been used; another reason might be to specifically disallow certain dangerous method calls. Whatever your reason for 
removing a definition, it should naturally be done with caution because it can conceivably lead to debugging problems.

The radical way to undefine something is with the `undef` keyword. You can `undef` methods, local vars, and constants
at the top level. Although a class name is a constant, you **cannot** remove a class definition this way.

You can't `undef` within a method definition or `undef` an instance variable.

The `remove_method` and `undef_method` methods are also available (defined in **Module**). The difference is subtle:
`remove_method` will remove the current (or nearest) definition of the method; `undef_method` will literally
cause the method to be undefined (removing it from superclasses as well).

The `remove_const` method will remove a constant:

```ruby
module Math
  remove_const :PI
end

# No PI anymore!
```

> It is possible to remove access to a class definition in this way (because a class identifier is simply a constant)
> ```ruby
> class BriefCandle
>   # ...
> end
> 
> out_out = BriefCandle.new
> 
> class Object
>   remove_const :BriefCandle
> end
> 
> BriefCandle.new     # NameError: uninitialized constant BriefCandle
> out_out.class.new   # Another BriefCandle instance
> ```

Methods such as `remove_const` and `remove_method` are (naturally enough) private methods. This is why we show these
being called from inside a class or module definition rather than outside.


### Handling References to Nonexistent Constants

The `const_missing` method is called when you try to reference a constant that isn't known. A symbol referring to
the constant is passed in. It is analogous to the `method_missing` method.

To capture a constant globally, define this method within **Module** itself (Remember that **Module** is the parent
of **Class**.)

```ruby
class Module
  def const_missing(x)
    "#{x} missing from Module"
  end
end

class X
end

p X::BAR    # BAR missing from Module
```


### Handling Calls to Nonexistent Methods

Sometimes it's useful to be able to write classes that respond to arbitrary method calls. For example, you might want to
wrap calls to external programs in a class, providing access to each program as a method call. You can't know ahead of 
time the names of all these programs, so you can't create the methods as you write the class.

For that purpose **Object**#`method_missing` and `respond_to_missing?` come to the rescue. Whenever a Ruby object receives
a message for a method that isn't implemented in the receiver, it invokes the `method_missing` method instead. You can use that
to catch what would otherwise be an error, treating it as a normal method call.

```ruby
class CommandWrapper
  private def method_missing(symbol, *args)
    system(method.to_s, *args)
  end
end

cw = CommandWrapper.new
cw.date               # Sat Jul 26 02:08:06 PDT 2014
cw.du '-s', '/tmp'    # 166749 /tmp 
```

If your `method_missing` handler decides that it doesn't want to handle a particular call, it should call `super` rather than
raising an exception. That allows `method_missing` handles in superclasses to have a shot at dealing with the situation.


### Improved Security with `taint`

The first feature of Ruby that defends against malice attacks is the **_safe level_**. The safe level is stored in a 
thread-local global variable and defaults to 0. Assigning a number to `$SAFE` sets the safe level, which can **never**
be decreased.

When the safe level is 1 or higher, Ruby starts blocking certain dangerous actions using tainted objects. Every object
has a tainted or non-tainted status flag. If an object has its origin in the **outside world**, it is automatically tainted.
This taint is passed on to objects that are derived from such an object.

> Many core methods behave differently or raise an exception when passed tainted data as the safe level increases.

|  |0|1|2|3|
|---|---|---|---|---|
|**$RUBYLIB** and **$RUBYOPT** are not honored| |✅|✅|✅|
|Current directory is not added to path| |✅|✅|✅|
|Disallows command-line options: **-e -i -l -s -x -S**| |✅|✅|✅|
|Disallows **$PATH** if any directory in it is world-writable| |✅|✅|✅|
|Disallows manipulation of a directory named by a tainted string| |✅|✅|✅|
|**chroot** will not accept a tainted string| |✅|✅|✅|
|**load/require** will not accept a tainted string (unless wrapped)| |✅|✅|✅|
|Cannot manipulate file or pipe named by a tainted string| |✅|✅|✅|
|**system** and **exec** will not accept a tainted string| |✅|✅|✅|
|**glob**, **eval**, and **trap** will not accept a tainted string| |✅|✅|✅|
|Cannot manipulate directories or use **chroot**| | |✅|✅|
|Cannot load a file from a world-writable directory| | |✅|✅|
|Cannot load a file whose name is tainted string starting with **~**| |✅|✅| |
|Cannot use **File** methods: **chmod**, **chown**, **lstat**, **truncate**, **flock**| | |✅|✅|
|Cannot use **File** class methods: **stat**, **umask**| | |✅|✅|
|Cannot use **IO** methods: **ioctl**, **stat**| | |✅|✅|
|Cannot use **Object** methods: **fork**, **syscall**, **trap**| | |✅|✅|
|Cannot use **Process** class methods: **setpgid**, **setsid**| |✅|✅| |
|Cannot use **Process** class methods: **setpriority**, **egid=**| |✅|✅| |
|Cannot use **trap** to handle signals| | |✅|✅|
|All objects are created tainted| | | |✅|
|Objects cannot be untainted| | | |✅|


### Defining Finalizers for Objects

Ruby classes have constructors but don't have destructors. That's because Ruby uses garbage collection to remove unreferenced
objects; a destructor would make no sense.

The truth is that there's no reliable way to handle the finalization of objects. However, you can arrange to have code called
when an object is garbage collected.

```ruby
ObjectSpace.define_finalizer(a) { |id| puts "Destroying #{id}" }
```

> Note: By the time the finalizer is called, the object has basically been destroyed already. An attempt to convert the ID
> you receive back into an object reference using `ObjectSpace._id2ref` will raise a **RangeError**, complaining that you are
> attempting to use a recycled object.
>
> Also, be aware that Ruby uses a "conservative" GC mechanism. There is no guarantee that an object will undergo garbage collection
> before the program terminates.


## Program Introspection

### Traversing the **Object Space**

The Ruby runtime system needs to keep track of all known (if for no other reason than to be able to garbage collect those
that are no longer referenced). This information is made accessible via the **ObjectSpace.`each_object`** method, only objects
of that type will be returned:

```ruby
ObjectSpace.each_object(Bignum) do |obj|
  printf "%20s: %\n", obj.class, obj.inspect
end

# Prints:
#   Bignum: 12398129471589217349182831
#   Bignum: 128391825012031
```

If all you're after is a count of each type of object that has been created, the `count_objects` method will
return a hash with object types and counts:

```ruby
require 'pp'

p ObjectSpace.count_objects
# {:TOTAL=>31231, :FREE=>124, ...etc}
```


### Examining the Call Stack

Sometimes we want to know who our caller was. This could be useful information if, for example, we had a 
fatal exception. The `caller` method, defined in **Kernel**, makes this possible. It returns an array of strings
in which the first element represents the caller, the next element represents the caller's caller, and so on:

```ruby
def func1 
  puts caller[0]
end

def func2
  func1
end

func2 # somefile.rb:6 in ‘func2’
```

Each string in the caller array takes the form `file:line: in method` 


### Tracking Changes to a Class or Object Definition

There are a variety of reasons why would one want to track such things, but to give an example: implementing some kind of a GUI-based debugger
and there's a need to refresh a list of methods if a user adds one on the fly.

```ruby
module Tracing
  def self.hook_method(const, meth)
    const.class_eval do
      alias_method "untraced_#{meth}", "#{meth}"
      define_method(meth) do |*args|
        puts "#{meth} called with params (#{args.join(', ')})"
        send("untraced_#{meth}", *args)
      end
    end
  end
  
  def self.included(const)
    const.instance_methods(false).each do |m|
      hook_method(const, m)
    end
    
    def const.method_added(name)
      return if @disable_method_added
      puts "The method #{name} was added to class #{self}"
      @disable_method_added = true
      Tracing.hook_method(self, name)
      @disable_method_added = false
    end
    
    if const.is_a(Class)
      def const.inherrited(name)
        puts "The class #{name} inherited from #{self}"
      end
    end
    
    if const.is_a?(Module)
      def const.extend(name)
        puts "The class #{name} extended itself with #{self}"
      end
      
      def const.included(name)
        puts "The class #{name} included #{self} into itself"
      end
    end
    
    def const.singleton_method_added(name, *args)
      return if @disable_singleton_method_added
      return if name == :singleton_method_added
      
      puts "The class method #{name} was added to the class #{self}"
      @disable_singleton_method_added = true
      singleton_class = (class << self; self; end)
      Tracing.hook_method(singleton_class, name)
      @disable_singleton_method_added = false
    end
  end
end
```