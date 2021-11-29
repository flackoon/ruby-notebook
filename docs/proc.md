## Proc

> A _Proc_ object is an **encapsulation of a block** of code, which can be **stored** in a local variable, 
> **passed** to a method or another _Proc_, and can be **called**.

> A closure **remembers** the context in which it was **created**. One way to create a closure is by using
> `Proc` object.

A quick example:

```ruby
def power(exponent)
  proc {|base| puts "Exponent: #{exponent} | base: #{base}"; base**exponent}
end

square = power(2)
cube = power(3)

a = square.call(11) # 121
b = square.call(5)  # 25
c = cube.call(6)    # 216
d = cube.call(8)    # 512
```