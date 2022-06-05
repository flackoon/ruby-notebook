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

