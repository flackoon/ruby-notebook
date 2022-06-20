# Methods and Their Arguments

## Naming methods

Similar to the local variable naming, there is a principle with method names, and that is that *the length of a method
name should be inversely proportional to how often the method will be called*.

If a method is called very frequently, you want it to have the shortest possible understandable name.

For methods that are not called frequently, or that you want to discourage users from calling frequently, it's good for
them to have long, descriptive names. It's not recommended to poke around the instance variables of other objects, so
`instance_variable_get` and `instance_variable_set` are used instead of something shorter. 

For methods that should only be called once during application initialization for configuring apps, it's a good idea
to give them very descriptive names.


## Using the many types of method arguments

The first thing to consider is whether a method needs arguments at all. There's a whole bunch of complexity you can avoid
if your method doesn't need an argument.

Methods that don't accept arguments (zero arity methods) are the fastest for Ruby to execute, so if you don't need a
method to have an argument, it's best to avoid it for performance reasons.


### Positional arguments

Other than the methods that don't accept arguments, methods that require a single positional argument are the next
simplest. You can think of a method arguments as local variables that are defined before the method is executed. That's
actually how Ruby implements method arguments.

After the method arguments that require a single positional argument, methods that require 2 positional arguments are
the next simplest. However, introducing a second argument adds a whole new dimension of complexity, and that's due to
argument order. When you have methods that accept more than one argument, you need to think carefully about the arguments
and what argument order makes sense.

In Ruby, its very rare to have methods that take more than one argument. It's even rarer for Ruby core classes to require
an exact number of more than 2 arguments. Only 3 methods do that, all of which take exactly three arguments and are very
rarely used.

> One reason that Ruby avoids methods with many required arguments is that method ordering issues become even more complex.
> There are only 2 ways to order 2 elements, but 6 ways to order 3 elements and 24 ways to order 4 elements.

One way to tackle multiple positional arguments for a method is to accept a single object that has many accessors, such
as a **Struct** class. This type of design encourages class proliferation, which leads to higher cognitive overhead.
Additionally, this approach requires object allocation, which in general is going to be bad for performance.

In general, the approach to creating a separate class for the argument only really makes sense if you will be passing
instances of the class to multiple methods and not just a single method, or if there are methods that will be returning
instances of the class.

> In other words, only create a separate class if creating a class makes sense in the domain model. Don't create a class
> just to avoid method argument ordering issues.


## Optional positional arguments

You can give any positional argument a default value, and that argument becomes optional. That's not completely accurate
because, as it turns out, you can only make a subset of arguments optional. For example, you can surround an optional
positional argument with two required positional arguments:

```ruby
def a(x, y=2, z)
  [x, y, z]
end

a(1, 3)
# => [1, 2, 3]
```

However, Ruby doesn't allow you to surround a required positional argument with 2 optional positional arguments:

```ruby
eval(<<END)
  def a(x=1, y, z=2)
  end
END
# SyntaxError
```

> ...There are four types of positional arguments in Ruby, and they must be given in this order:
> 1. Leading arguments
> 2. Optional arguments
> 3. Rest argument
> 4. Post arguments
>
> Each argument type can have zero arguments, and there can be multiple arguments of each type, except for the rest
> argument.

<details>
  <summary>A few examples</summary>

  ```ruby
  def a(x, y=2, z)
  end
  ```

  The `x` argument is a leading argument, the `y` argument is an optional argument, and the `z` argument is a post
  argument.


  ```ruby
  eval(<<END)
    def a(x=1, y, z=2)
    end
  END
  ```

  No leading arguments here; the `x` argument is an optional one, the `y` is a post argument, and a **SyntaxError** is
  raised when parsing the `=` sign after the `z` argument. This is because Ruby's syntax doesn't expect a default argument
  value for post arguments.

  In general, methods in Ruby rarely have post arguments. If a method uses optional arguments, it will almost always be
  written as follows:

  ```ruby
  def a(x, y=nil)
  end
  ```

  It's fairly rare to define methods like so:

  ```ruby
  def a(x=nil, y)
  end
  ```

</details>

In general, it's best to avoid putting optional arguments before required arguments.


## Rest arguments

Rest arguments in Ruby are only allowed, at most, once in a method definition, and take all the positional arguments in
the method call that are not taken by the lead, optional, and post arguments as values. They are also different from the
other types of positional arguments in that the rest argument does not need a name.

```ruby
def foo(bar, *)
end
```

This format can be used if you want to ignore arguments, but that's almost always a sign of poor method design. The only
good use case for this is when you are calling `super` with no argument, which will implicitly pass the same arguments.

```ruby
def foo(bar, *)
  bar = 2
  super
end
```

> `super` passes the same local variables given as arguments to the `super` method, which reflects the new values of the
> local variables.
> Internally, when you don't give the rest argument a name, Ruby gives it a name internally that you can't access so that
> it can be passed in a `super` call.

When you're considering whether a method should support a rest argument, you should always consider whether it is better
to accept a single array argument instead. After all, Ruby will be internally generating an array for you if you use a
rest argument.


<details>
  <summary>Frozen constant approach</summary>

  If you need to ensure that a method doesn't mutate its argument:

  ```ruby
  EMPTY_ARRAY = [].freeze
  def a(bar = EMPTY_ARRAY)
    bar << 1
  end
  ```

  This is because it's a bad idea for a method to mutate any arguments unless that is the purpose of the method. One
  advantage of using the frozen constant approach is that it isn't just a performance optimization - it also catches
  cases where you are accidentally mutating the method argument.

  If you want to mutate the argument, you should `dup` it first.

</details>


## Keyword arguments

In most cases, the keyword arguments are optional, so it is common practice to make the default value of the argument an
empty hash:

```ruby
def foo(options={})
end
```

As with rest arguments, this causes a hash allocation on every call to the method when no options are provided. To
optimize this case and avoid a hash being allocated to every method call without an options argument, you can take a
similar approach as in the previous section and use a frozen hash constant.

However, using the keyword syntax when calling the method always allocates a hash, because the hash is created before the
method is called:

```ruby
foo(:bar => 1)
```

By default unrecognized keywords passed are ignored, instead of triggering an **ArgumentError**.

As an alternative to the historical approach of handling keywords via a final positional hash argument, support for
keyword arguments in method definitions was added in Ruby 2.0:

```ruby
def foo(bar: nil)
end
```

This type of keyword argument has nice properties. It offers better performance because calling the method does **not**
allocate a hash.

```ruby
# No allocations
foo
foo(bar: 1)

# This allocates a hash
hash = {bar: 1}

# But in Ruby 3, calling a method with a keyword splat does not allocate a hash
foo(**hash)
```

More importantly, passing an unrecognized keyword argument will trigger an error:

```ruby
foo(baz: 1)
# Argument error (unknown keyword: :baz)
```

<details>
  <summary>Ruby 2 kwargs issues</summary>

  In Ruby 2, there were issues with using keyword arguments, because they were not fully separated from positional
  arguments. This especially affected methods that used optional arguments or rest arguments in addition to keyword
  arguments. In these cases, Ruby 2 would treat a final positional hash argument as keywords:

  ```ruby
  def foo(*args, **kwargs)
    [args, kwargs]
  end

  # Keywords treated as keywords, good!
  foo(bar: 1)
  # => [[], {:bar=>1}]

  # Hash treated as keywords, bad!
  foo({bar: 1})
  # => [[], {:bar=>1}]
  ```

  In Ruby 3, these issues have been resolved, and Ruby always separates positional arguments from keyword arguments.

</details>

Accepting arbitrary keywords still always allocates a hash:

```ruby
def foo(**kwargs)
end
```

<details>
  <summary>Hash allocation in Ruby 3</summary>

  If you are doing keyword argument delegation through multiple methods, this can add up as it allocates a hash per delegating
  method:

  ```ruby
  def foo(**kwargs)
    bar(**kwargs)
  end

  def bar(**kwargs)
    baz(**kwargs)
  end

  def baz(key: nil)
    key
  end

  # 2 hash allocations
  foo
  ```

  When delegation is used, the positional argument with a default value still performs better since you can avoid hash
  allocation completely:

  ```ruby
  def foo(options = OPTIONS)
    bar(options)
  end

  def bar(options = OPTIONS)
    baz(options)
  end

  def baz(options = OPTIONS)
    key = options[:key]
  end

  # 0 hash allocations
  foo
  ```

</details>

It is possible to avoid hash allocations when using keywords, but only if you know which method you are delegating to,
and which keywords the method accepts. This approach does not work for generic delegation methods, but is the fastest
option if it can be used.

The main issue with explicit keyword delegation is that it is significantly more difficult to maintain, especially with
many keywords. If the absolute maximum performance is required, you should prefer positional arguments as they are more
optimized.

> In most cases, for new code, it is best to use keyword arguments instead of an optional positional hash arguments.
> One thing to consider for new methods is the sue of the `**nil` syntax in method definitions, which marks the method
> as not accepting keyword arguments.
>
> ```ruby
> def foo(bar, **nil)
> end
> ```
>
> Since the method doesn't accept keyword arguments, Ruby will convert the keywords into a positional hash argument for
> backwards compatibility with historical code that accepts a positional argument.

By doing this, you break the callers of this method:

```ruby
def foo(bar, baz:nil)
  bar
end

foo(bar: 1)
# ArgumentError (wrong number of arguments)
```

Because the `foo` method now accepts keyword arguments, Ruby no longer performs keyword to positional hash conversion,
thereby breaking the called. You can avoid this issue for new methods with the `**nil` syntax.
