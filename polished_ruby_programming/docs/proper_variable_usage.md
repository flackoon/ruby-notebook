# Proper Variable Usage

## Increasing performance by adding local variables

Local variables require the least indirection. When accessing one in Ruby, the VM knows the location of the local
variable, and can more easily access the memory. Additionally, in most cases, the local variables are stored on the
virtual machine stack, which is more likely to be in the CPU cache.

<details>
  <summary>Optimizing proc example</summary>

  Let's say you want to have a **TimeFilter** class, such that you can pass an instance of it as a block when filtering:

  ```ruby
  time_filter = TimeFilter.new(Time.local(2020, 10),
                               Time.local(2020, 11))
  array_of_times.filter!(&time_filter)
  ```

  You also want to be able to leave out either of the ends, to only filter the times in one direction. One other desired
  usage is to separate the times that are in the filter from the times that are out of it, using the `partition` method.

  ```ruby
  after_now = TimeFilter.new(Time.now, nil)
  in_future, in_past = array_of_times.partition(&after_now)
  ```

  You could implement this as a method on **Enumerable**, but if you are writing a general-purpose library, you should
  not modify core classes unless this is the purpose of the library.

  Here's one way this could be implemented.

  ```ruby
  class TimeFilter
    attr_reader :start, :finish

    def initialize(start, finish)
      @start = start
      @finish = finish
    end

    def to_proc
      proc do |value|
        next false if start && value < start
        next false if finish && value > finish
        true
      end
    end
  end
  ```

  But this approach is way less efficient than it could otherwise be. The issue is with the implementation of `to_proc`.
  Every time the proc is called, it calls `attr_reader` to get the start time, if there is one. Same goes for the end
  time. So this is a maximum total of 4 calls during each block iteration.

  So the first thing you could do is to cache the result of the method call to a local variable:

  ```ruby
  def to_proc
    proc do |value|
      start = self.start
      finish = self.finish

      next false if start && value < start
      next false if finish && value > finish
      true
    end
  end
  ```

  That doesn't quite double the performance of the proc, since there is definitely time spent in the arithmetic comparison.

  You can hoist the setting of the local variables before the proc. Code inside the proc can still access the local
  variables, since the proc operates as a closure, capturing the surrounding environment.

  ```ruby
  def to_proc
    start = self.start
    finish = self.finish

    proc do |value|
      next false if start && value < start
      next false if finish && value > finish
      true
    end
  end
  ```

  Because you are retrieving the **start** and **finish** variables before creating the proc, you can use them to make
  the returned proc more efficient.

  ```ruby
  def to_proc
    start = self.start
    finish = self.finish

    if start && finish
      proc {|value| value >= start && value <= finish}
    elsif start
      proc {|value| value >= start}
    elsif finish
      proc {|value| value <= finish}
    else
      proc {|value| true}
    end
  end
  ```

</details>

> Anytime you have code that can be called multiple times, using a local variable at the highest possible level to cache
> the results of methods will speed code up.

However, local variables can be used to replace not just method calls, but also constants. For **very** 
performance-sensitive code that accesses constants, you can optimize it by storing constant references in local
variables.


## Avoid unsafe optimizations

One thing to remember when using local variables to optimize code is that you can only use this approach if the expression
you are storing in the local variable is idempotent, meaning that it does not have side effects.

<details>
  <summary>Array iteration example</summary>

  For example, consider the following code, where you are processing a large array in order to set values in a hash:

  ```ruby
  hash = some_value.to_hash
  large_array.each do
    hash[_1] = true unless hash[:a]
  end
  ```

  In this case it looks like you could use a local variable to improve performance:

  ```ruby
  hash = some_value.to_hash
  a_value = hash[:a]
  large_array.each do
    hash[_1] = true unless a_value
  end
  ```

  Unfortunately, such optimization is not safe in the general case. One issue is that **large_array** could contain `:a`
  as an element, and the purpose of the original code is to stop when `:a` is found. A less likely but still possible case
  that could have a problem is that the hash could have a default proc that sets or removes the `:a` entry for the hash.

</details>

You should also avoid this approach when dealing with values that change over time, at least when you cannot ensure how
long the values will last.


## Handling scope gate issues

Local variables in Ruby are in scope from the first time Ruby comes across them while parsing until the end of the scope
they are defined in unless they hit a scope gate. IN that case, they are not in scope inside the scope gate.

> In other words, the scope gate grates a new local variable scope.

<details>
  <summary>Scope gates example</summary>
  
  The following scope gate shows that at the start of each scope gate, there are no local variables:

  ```ruby
  defined?(a) # nil
  a = 1
  defined?(a) # 'local-variable'

  module M
    defined?(a) # nil
    a = 2
    defined?(a) # 'local-variable'

    class C
      defined?(a) # nil
      a = 3
      defined?(a) # 'local-variable'

      def m
        defined?(a) # nil
        a = 4
        defined?(a) # 'local-variable'
      end
      a # 3
    end
    a # 2
  end
  a # 1
  ```

</details>

After the scope gate exits, the previous scope is restored and the value of the local variable remains the same as before
the scope gate was entered.

All scope gates in Ruby have alternatives that do not add scope gates. The `def` keyword can be replaced with
`define_method`, `class` with `Class.new`, and `module` with `Module.new`. All replacements accept a block, and blocks
in ruby are **not** scope gates. Any local variables newly defined in a block are local to the block and blocks contained
inside of it but are not available to the code outside.

<details>
  <summary>Defied scope gates example</summary>
  
  ```ruby
  defined?(a) # nil
  a = 1
  defined?(a) # 'local-variable'

  M = Module.new do
    defined?(a) # 'local-variable'
    a = 2

    self::C = Class.new do
      defined?(a) # 'local-variable'
      a = 3

      define_method(:m) do
        defined?(a) # 'local-variable'
        a = 4
      end
      a # 3
    end
    a # 3
  end
  a # 3
  ```

</details>

Unlike the code that uses scope gates, after these blocks return, the value of `a` remains the same as before the block
return since ach block uses the same local variable.

And even worse, calling the `m` method on the `M::C` instance overrides the local variable of the surrounding scope.

The trade-off of using the gateless equivalents is that they can significantly improve performance. If a method is called
often and performs a computation that can be cached, it makes sense to precompute the result and use `define_method`
instead of using `def`.

Another use case for combining local variables with `define_method` is for information hiding. Let's say you want to
define a method that is thread-safe, so it uses a mutex.

<details>
  <summary>Information hiding example</summary>

  ```ruby
  class T
    MUTEX = Mutex.new
    def safe
      MUTEX.synchronize do
        # non-thread-safe code
      end
    end
  end
  ```

  The problem with this code is users can easily poke around and use the constant directly:

  ```ruby
  T::MUTEX.synchronize{T.new.safe}
  ```

  This results in thread deadlock. One way to discourage this behavior is to use a private constant:

  ```ruby
  class T
    MUTEX = Mutex.new
    private_constant :MUTEX

    def safe
      MUTEX.synchronize do
        # non-thread-safe code
      end
    end
  end
  ```

  This makes it slightly more difficult for the user, as accessing `T::MUTEX` directly will raise **NameError**. However
  you can work around private methods with `Module#const_get`:

  ```ruby
  T.const_get(:MUTEX).synchronize{T.new.safe}
  ```

  In general, users that are accessing private constants deserve what they get, but if you want to make it even more
  difficult, you can use a local variable and `define_method`:

  ```ruby
  class T
    mutex = Mutex.new
    define_method(:safe) do
      mutex.synchronize do
        # non-thread-safe code
      end
    end
  end
  ```

</details>


## Naming considerations with local variables

How do you decide what length of variable name is appropriate?

> The general principle in local variable naming is that the length of the variable name should be roughly proportional
> to the inverse of the size of the scope of the variable, with the maximum length being the length of the name that
> most accurately describes the variable.

For example, if you are calling a method that accepts a block, and the block is only a single line or a few lines, and
the receiver of the method or the method name makes it obvious what block will be yielded, then it may make sense to use
a single-letter variable:

```ruby
@albums.each do |a|
  puts a.name
end
```

Because **album** is a fairly small name, it would also be reasonable to use **album** as a local variable name:

```ruby
@albums.each do |album|
  puts album.name
end
```

However, if the context doesn't make it obvious what is being yielded, then using a single letter variable name is a bad
idea.

Additionally, if the fully descriptive variable name is very long, it's a bad idea to use it for single-line blocks:

```ruby
TransactionProcessingSystemReport.each do |transaction_processing_system_report|
  puts transaction_processing_system_report.name
end
```

Using the full name in this case makes it harder to read, and the clarity of the longer name adds no value. In cases like
this, you may not want to use a single variable name, but you should probably at least abbreviate the name (to
`tps_report` in the last example).

Or even do this:

```ruby
TransactionProcessingSystemReport.each do |report|
  puts report.name
end
```


## Learning how best to use instance variables

Almost all objects in Ruby support instance variables. The exceptions are the immediate objects: `true`, `false`, `nil`,
integer, floats, and symbols. The reason is that they lack their own identity. Ruby is written in C, and internally to
Ruby, all objects are stored using the `VALUE` type. `VALUE` usually operates as a pointer to another, larger location
in memory (called the Ruby heap). In that larger location in memory is where instance variables are stored directly, or
if there isn't enough storage, a pointer to a separate location in memory where they are stored.

Immediate objects are different from all other objects in that they are not pointers, they contain all information about
the object in a single location in memory that is the same size as a pointer. This means there is no space for them to
contain instance variables.

Additionally, unlike most other objects, conceptually there are no separate instances of immediate objects, unlike other
objects.


## Increasing performance with instance variables

As with local variables, you can increase performance by adding instance variables. The same principles for optimizing
with local variables, in general, apply to instance variables. Most times where you have a method that is likely to be
called multiple times and where the method is idempotent, you can store the result of the calculation in an instance
variable to increase performance.

> If an object method that does some heavy lifting is called multiple times throughout the average time of the object,
> then storing the result of the calculation in an instance variable can significantly improve performance.

<details>
  <summary>Caching via instance variable example</summary>

  Let's assume you have an **Invoice** class that accepts an array of **LineItem** instances, containing info about the
  items purchase. When preparing the invoice, the total tax needs to be calculated:

  ```ruby
  LineItem = Struct.new(:name, :price, :quantity)

  class Invoice
    def initialize(line_items, tax_rate)
      @line_items = line_items
      @tax_rate = tax_rate
    end

    def total_tax
      @tax_rate * @line_items.sum{|item| item.price * item.quantity}
    end
  end
  ```

  If `total_tax` is only called once in the average lifetime of the **Invoice** instance, then it doesn't make sense to
  cache the value of it, and caching the value of it can make things slower and require increased memory. However, if
  it is called multiple times in the lifetime of an **Invoice** instance, caching the value can significantly improve
  performance.

  ```ruby
  def total_tax
    @total_tax ||= @tax_rate * @line_items.sum{|item| item.price * item.quantity}
  end
  ```

</details>

There are couple of cases where using an instance variable cannot be used. First, this approach works only if the
expression being called cannot result in a `false` or `nil` value. Otherwise because of the `||=` operator, the expression
will keep reevaluating.To handle this case, you should use an explicit `defined?` check for the instance variable:

```ruby
def total_tax
  return @total_tax if defined?(@total_tax)
  @total_tax = @tax_rate * @line_items.sum{|item| item.price * item.quantity}
end
```

You can also be more explicit about it and use `instance_variable_defined?` instead of `defined?`, but it is recommended
that you use `defined?` because Ruby is better able to optimize it. This is because `defined?` is a keyword and
`instance_variable_defined?` is a regular method, and the Ruby VM optimizes the `defined?` keyword into a direct instance
variable check.

The second case where you cannot use this check is when the **Invoice** instance is frozen. You cannot add instance
variables to frozen objects. The solution then is to have an unfrozen instance variable hash inside the frozen object.
Because the unfrozen hash can be modified, you can still cache values in it.

<details>
  <summary>Unfrozen hash cache instance variable example</summary>

  ```ruby
  LineItem = Struct.new(:name, :price, :quantity)

  class Invoice
    def initialize(line_items, tax_rate)
      @line_items = line_items
      @tax_rate = tax_rate
      @cache = {}
      freeze
    end

    def total_tax
      @cache[:total_tax] ||= @tax_rate * @line_items.sum{|item| item.price * item.quantity}
    end
  end
  ```

  Like the instance variable approach, the previous example also has issues if the expression evaluates to `nil` or `false`.
  You can fix those using a similar approach with `key?` instead of `defined?`.

  ```ruby
  def total_tax
    return @cache[:total_tax] if @cache.key?(:total_tax)
    @cache[:total_tax] = @tax_rate * @line_items.sum{|item| item.price * item.quantity}
  end
  ```

</details>

The other issue with this approach, and with caching in general using instance variables, is that, unlike local variables,
you probably do not have control over the entire scope of the instance. If any of the objects in the expression being
cached are mutable, there is a chance that the cached value could become inaccurate.

<details>
  <summary>Securing/Enhancing instance variable caching example</summary>

  If `line_items` in the previous example gets modified after the `total_tax` is once calculated, then we have a problem:

  ```ruby
  line_items = [LineItem.new('Foo', 3.5r, 10)]
  invoice = Invoice.new(line_items, 0.095r)
  tax_was = invoice.total_tax
  line_items << LineItem.new('Bar', 4.2r, 10)
  tax_is = invoice.total_tax
  ```

  With this example, `tax_was` and `tax_is` will be the same value, even though the **Invoice** instance's line items
  have changed.

  To tackle this issue, there are a couple of approaches. The first one is to duplicate the line items, so that changes
  to the line items used as an argument do not affect the invoice:

  ```ruby
  def initialize(line_items, tax_rate)
    @line_items = line_items.dup
    @tax_rate = tax_rate
    @cache = {}
    freeze
  end
  ```

  The second approach is freezing the line items. This is a better approach, except that it mutates the argument, and in
  general it is a bad idea for any method to mutate arguments that it doesn't control unless that is the sole purpose of
  the method.

  ```ruby
  def initialize(line_items, tax_rate)
    @line_items = line_items.freeze
    # ...
  end
  ```

  The safest approach is the combination of both approaches:

  ```ruby
  @line_items = line_items.dup.freeze
  ```

  This makes sure that the array of line items cannot be modified. However, there is still a way for the resulting
  calculation to go stale, and that is if one of the line items is modified directly.

  To avoid this issue, you need to make sure you can freeze the line items. One approach is to make all **LineItem**
  instances frozen:

  ```ruby
  LineItem = Struct.new(:name, :price, :quantity) do
    def initialize(...)
      super
      freeze
    end
  end
  ```

  Or if you only want to freeze the line items given on the invoice, you can map over the list of line items and return
  a frozen dump of each item:

  ```ruby
  def initialize(line_items, tax_rate)
    @line_items = line_items.map do |item|
      item.dup.freeze
    end
    # ...
  end
  ```
</details>


## Handling scope issues with instance variables

One of the main issues to be concerned with when using instance variables is using them inside blocks passed to methods
you don't control. Let's assume you were using the **Invoice** class from the previous section, but you want to add a
method named `line_item_taxes` that returns an array of taxes, one for each line item.

```ruby
class Invoice
  def line_item_taxes
    @line_items.map do |item|
      @tax_rate * item.price * item.quantity
    end
  end
end
```

This would work in most cases, but there's a case where it would fail. In this example, you are assuming that `@line_items`
is an array of **LineItem** instances. Instead of a simple array, the passed-in `line_items` argument could be an
instance of a separate class:

```ruby
class LineItemList < Array
  def initialize(*line_items)
    super(line_items.map do |name, price, quantity|
      LineItem.new(name, price, quantity)
    end)
  end

  def map(&block)
    super do |item|
      item.instance_eval(&block)
    end
  end
end

Invoice.new(LineItemList.new(['Foo', 3.5r, 10]), 0.095r)
```

One reason to implement such a class is to make it easier to construct a literal list of line items, by just providing
arrays of name, price and quantity, and having it automatically create the **LineItem** instances. To make it even easier
for the user, the **LineItemList** class has a `map` method that evaluates the block passed to it in the context of the
item. This allows for simpler code inside the block, as long as you are only accessing local variables and methods of
the current line item.

```ruby
line_item_list.map do
  price * quantity
end
```

Instead of the more verbose code:

```ruby
line_item_list.map do |item|
  item.price * item.quantity
end
```

The trade-off is that doing this changes the scope of the block from caller's scope to the scope of the line item, hence,
`@tax_rate` references no longer to the invoice, but to the line item.

```ruby
class Invoice
  def line_item_taxes
    @line_items.map do |item|
      @tax_rate * item.price * item.quantity
    end
  end
end
```

You can, of course, work around by assigning the instance variable to a local variable before the block. That's probably
a good idea anyway, as it is likely to improve the overall performance.

```ruby
class Invoice
  def line_item_taxes
    tax_rate = @tax_rate
    @line_items.map do |item|
      tax_rate * item.price * item.quantity
    end
  end
end
```

> Issues like this are one reason why it's generally a **bad** idea for code to use methods such as `instance_eval` and
> `instance_exec` without a good reason. Using `instance_eval` and `instance_exec` on blocks that are likely to be called
> inside user code, as opposed to blocks used for configuration, can be a common source of bugs.


## Understanding how constants are just a type of variable

Ruby's constants are actually variables. It's not even an error in Ruby to reassign a constant; it only generates a
warning. 

At best, Ruby's constants should be considered only as a recommendation. That being said, not modifying a constant is a
good recommendation.


## Handling scope issues with constants

Constant scope in Ruby is different than both local variable scope or instance variable scope. In some ways, it is lexical,
but it's not truly lexical as the constant doesn't have to be declared in the same lexical scope in which it is accessed.


It's easiest to learn Ruby constant scope rules by examples.

<details>
  <summary>Constants resolution example</summary>

  ```ruby
  class A
    W = 0
    X = 1
    Y = 2
    Z = 3
  end

  class Object
    U = -1
    Y = -2
  end

  class B < A
    X = 4
    Z = 5
  end

  class B
    U # -1 from Object
    W # 0 from A
    X # 4 from B
    Y # 2 from A
    Z # 5 from B
  end
  ```

</details>


From this example, we know that the class lookup will look first at the class or module for the constant, and only at
superclasses of the class or module if the constant isn't found in the class directly, and if the superclass doesn't
contain the constant, continue recursively up the ancestor chain.

<details>
  <summary>Continue previous example</summary>

  For a single-class definition, that's all you need to worry about in regards to constants resolution. However, it gets
  significantly more complex when you have a class or module definition inside another class or module definition.

  ```ruby
  class C < A
    Y = 6
  end

  class D
    Z = 7
  end

  class E < D
    W = 8
  end

  class E
    class ::C
      U # -1, from Object
      W # 8, from E
      X # 1, from A
      Y # 6, from C
      Z # 3, from A
    end
  end
  ```

</details>

So Ruby's constant lookup algorithm looks like this:

> 1. Look into the current namespace.
> 2. Look in the lexical namespaces containing the current namespace.
> 3. Look in the ancestors of the current namespace, in order.
> 4. Do not look in ancestors of the lexical namespaces containing the current namespace.


## Visibility differences between constants and class instance variables

One significant difference between constants and class instance variables is that constants are externally accessible by
default, whereas class instance variables are like all instance variables and not externally accessible by default.

You can make class instance variables externally accessible similarly to how you make instance variables accessible to
regular objects, by calling `attr_reader`/`attr_accessor`.

```ruby
class A
  @a = 1

  class << self
    attr_reader :a
  end
end

A.a # 1
```

## Naming considerations with constants

The naming of constants depends on whether they are classes/modules or other objects. Classes and modules should use
**CamelCase**. Other objects should use **ALLCAPS_SNAKE_CASE**. Ruby follows these conventions internally. You have class
names such as **ArgumentError** and **BasicObject**, and other constant names such as **TOPLEVEL_BINDING** and
**RUBY_ENGINE**.


## Replacing class variables

There are a few features in Ruby you should never use, and class variables are one of them.

To give a few examples as to why:

```ruby
class A
  @@a = 1
end

class B < A
  @@a = 2
end
```

Changing a class variable in the subclass affects the class variable in the superclass as well. This is because class
variables aren't really specific to a class but to a class hierarchy. Therefore, you can never safely define a class
variable in any class that is subclassed or any module that is included in other classes.

And it get's worse. If you define a class variable in a subclass, that doesn't exist in the superclass, if you try to
access it from the superclass, you get **NameError**, which is fine. If you on a later stage define that same variable
in the superclass, though, when you try to access it in the subclass, you get **RuntimeError**, which effectively breaks
the subclass.


## Replacing class variables with constants

One possible approach to replacing class variables is using constants method.

The big downside of this approach is that Ruby warns you when you change the value of a constant. Also, you can't set a
constant inside a method, at least not using the standard constant setting syntax:

```ruby
class B
  C = 2

  def increment
    C += 1 # SyntaxError - dynamic constant assignment
  end
end
```

You have to use **Module#`const_get`**:

```ruby
class B
  def increment
    self.class.const_set(:C, C + 1)
  end
end
```

That would still warn on every call on the method though.

Because a constant can refer to a mutable object, it is possible to allow reassignment behavior without actually
reassigning the constant itself:

```ruby
class B
  C = [0]

  def increment
    C[0] += 1
  end
end
```

This approach can definitely be considered a hack and not an implementation recommendation. It's bad to use this approach,
for the same reason it is bad to rely on globally mutable data structures in general. In any case where you'll be
reassigning the value, it is bad idea to use a constant, and you should use one of the next two approaches instead.


## Replacing class variables with class instance variables using the superclass lookup approach

If you cannot replace your class variable with a constant because you are reassigning it, you should replace it with a
class instance variable. However, like all instance variables, class instance variables are specific to the class itself
and are not automatically propagated to subclasses.

```ruby
class A
  @c = 1
end

class B < A
end
```

If you want to get the value of `@c` from **B** using the superclass lookup approach, you need to either use a recursive
or iterative approach to look in the superclasses.

```ruby
class B
  is defined?(@c)
    c = @c
  else
    klass = self
    while klass = klass.superclass
      if klass.instance_variable_defined?(:@c)
        c = klass.instance_variable.get(:@c)
        break
      end
    end
  end
end
```

This approach is very verbose for such a task though. The recursive approach is similar, it just uses recursion instead
of iteration in the lookup method. This is much simpler in terms of code, and it performs better as well, due to fewer
and simple method calls.

```ruby
def A.c
  defined?(@c) ? @c : superclass.c
end
```

One advantage of the superclass lookup approach is that if you change the class instance variable value in the superclass
without changing in the subclass, calling the lookup method in the subclass will reflect the changed value in the
superclass.

Another advantage is that the superclass approach uses minimal memory. The disadvantage is the variable lookup can take
significantly more time, at least for deep hierarchies, especially if it is unlikely you'll be changing the value in the
subclasses.

This is a classing processing time versus memory trade-off. The superclass lookup approach makes the most sense if reduced
memory is more important than processing time.


## Replacing class variables with class instance variables using the copy to subclass approach

This is an alternative to the superclass lookup approach – copying each instance variable into the subclass when the
subclass is created.

```ruby
class A
  @c = 1

  def self.inherited(subclass)
    subclass.instance_variable_set(:@c, @c)
  end
end

class B < A
  @c # 1
end
```

Advantages:\
✅ You can access the instance variables directly in the subclasses without having to use a special method\
✅ It's faster to access the values in subclasses

Disadvantages:\
❌ If you change the value of a variable in the superclass, the subclass won't reflect that change\
❌ This approach requires too much memory, especially if you have large number of instance variables


## Avoiding global variables, most of the time

In general, using global variables in Ruby is discouraged unless it's necessary. Some examples where it makes sense to use
them is when modifying the load path:

```ruby
$LOAD_PATH.unshift('../lib')
```

Or when silencing warnings in a block (you really got to have a very good reason to do this):

```ruby
def no_warnings
  verbose = $VERBOSE
  $VERBOSE = nil
  yield
ensure
  $VERBOSE = verbose
end
```

Or lastly, when reading/writing to the standard input, output, or error:

```ruby
$stdout.write($stdin.read) rescue $stderr.puts($!.to_s)
```

The main issues with using global variables in Ruby are the same as using global variables in any programming language,
in that it encourages poor coding style and hard-to-follow code. Additionally, because there's only one shared namespace
for global variables, there is a greater chance of variable conflicts.

Using an approach that avoids global variables while keeping the same architecture doesn't fix anything. If you need
information in a low-level part of your app that comes from a high-level part of your app, don't make the shortcut of
using a global variable or any similar approach. Properly pass the data as method arguments all the way down. Otherwise
you are setting yourself up for long-term problems.

<details>
  <summary>Using constant object instead of a global variable example</summary>

  For example, if you are writing a batch processing system for invoices and you want to print a period for every 100
  invoices processed as a minimal form of progress indicator, you could use a global variable as a quick way to implement
  it.

  ```ruby
  $invoices_processed = 0
  # ...
  $invoices_processed += 1
  if $invoices_processed % 100 == 0
    print '.'
  end
  ```

  To avoid the use of a global variable, it's possible to switch to a constant object with some useful helper methods:

  ```ruby
  INVOICES_PROCESSED = Object.new
  INVOICES_PROCESSED.instance_eval do
    @processed = 0

    def processed
      @processed += 1
      if @processed % 100 == 0
        print '.'
      end
    end
  end
  ```

  And when you process an invoice, you can use simpler code:

  ```ruby
  INVOICES_PROCESSED.processed
  ```

</details>


> About the only time to use a global variable instead of a singleton method or a specialized constant is when you need
> the absolute maximum performance, as global variable getting and setting is faster than calling a method. In all other
> cases, defining your own global variables should be avoided.
