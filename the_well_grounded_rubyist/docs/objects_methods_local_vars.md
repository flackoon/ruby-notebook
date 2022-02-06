# Objects, methods, and local variables

1. [Talking to objects](#talking-to-objects)\
   1.1. [The return value of a method](#the-return-value-of-a-method)
2. [A close look at method arguments](#a-close-look-at-method-arguments)\
   2.1. [Required and optional arguments](#required-and-optional-arguments)

## Talking to objects


### The return value of a method

The return value of any method is the same as the value of the last expression evaluated during execution of the method.

You have to use the **return** keyword if you want to return multiple values, which will be automatically wrapped up in
an array: `return a, b, c` rather than just `a, b, c` (although you can also return multiple values in an explicit array).


## A close look at method arguments

### Required and optional arguments

The `*x` notation means that when you call the method, you can supply any number of arguments (or none). In this case the
variable `x` is assigned an array of values corresponding to whatever arguments were sent.

### Order of parameters and arguments

> Ruby tries to assign values to as many variables as possible. And the sponge (`*`) parameters get the lowest priority:
> if the method runs out of arguments after it's performed the assignments of required arguments, then a catch-all 
> parameter ends up as an empty array.

In a method definition like the one below

```ruby
def mixed_args(a, b, *c, d)
  puts "Arguments:"
  p a, b, c, d 
end
```

the call `mixed_args(1, 2, 3, 4, 5)` would print `1, 2, [3, 4], 5`. But the call `mixed_args(1, 2, 3)` would print 
`1, 2, [], 3`.

So in a nutshell, the arguments priority list looks like so: `Required > Optional (with default value) > Sponge`.


### What you can't do in argument lists

Parameters have a pecking order. Required ones get priority, whether they occur at the left or at the right of the list.
All the optional ones have to occur in the middle.

You can have required arguments on the left only or on the right only – or both.

What you can't do is put the argument sponge to the left of of any default-valued arguments. For example:

```ruby
def broken_args(x, *y, z=1)
end
```

It's syntax error, because theres no way it could be correct. Once you've given **x** its argument and sponged up all the
remaining arguments in array **y**, nothing can ever be left for **z**. And if **z** gets the right-hand argument, leaving
the rest for **y**, it makes no sense to describe **z** as "optional" or "default-valued"

### References and method arguments

If you have a method:

```ruby
def change_string(str)
   str.replace("New string content!")
end
```

and call it like so:

```ruby
s = "Original string"
change_string(s)
puts s # New string content!
```

This happens because when we called `change_string`, we really just passed the object reference. And once a method has a
hold of a reference, any changes it makes to the object through the reference are visible when you examine the object 
through any of its references.

Ruby has some techniques for protecting objects from being changed, should you wish or need to do so.

#### Duping and freezing objects

If you want to protect objects from being changed inside methods to which you send them, you can duplicate them:
```ruby
s = "Original string"
change_string(s.dup)
puts s # Original string
```

You can also freeze an object, which prevents it from undergoing further change:

```ruby
s = "Original string"
s.freeze
change_string(s)  # FrozenError
```

There's also the `clone` method that's a lot like `dup`. The difference is that if you **clone** a frozen object, the 
clone is also frozen – whereas if you **dup** a frozen object, the duplicate isn't frozen.
