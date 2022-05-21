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
