~~# OOP and Dynamic Features in Ruby

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
