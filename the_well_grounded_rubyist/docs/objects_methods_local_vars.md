# Objects, methods, and local variables

1. [Talking to objects](#talking-to-objects)\
   1.1. [The return value of a method](#the-return-value-of-a-method)\

## Talking to objects


### The return value of a method

The return value of any method is the same as the value of the last expression evaluated during execution of the method.

You have to use the **return** keyword if you want to return multiple values, which will be automatically wrapped up in
an array: `return a, b, c` rather than just `a, b, c` (although you can also return multiple values in an explicit array).


## A close look at method arguments

### Required and optional arguments

The `*x` notation means that when you call the method, you can supply any number of arguments (or none). In this case the
variable `x` is assigned an array of values corresponding to whatever arguments were sent.

Parameters have a pecking order. Required ones get priority, whether they occur at the left or at the right of the list.
All the optional ones have to occur in the middle.

You can have required arguments on the left only or on the right only – or both.

What you can't do is put the argument sponge to the left of of any default-valued arguments. For example:

```ruby
def broken_args(x, *y, z=1)
end
```
