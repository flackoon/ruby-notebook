## Coding at runtime

We have already discussed load and require, but it is important to realize that these are not 
built-in statements or control structures or anything of that nature; they are actual methods. 
Therefore, it is possible to call them with variables or expressions as parameters or to call 
them conditionally. Contrast with this the #include directive in C or C++, which is evaluated 
and acted on at compile time.\

Code can be constructed piecemeal and evaluated. As another contrived example, consider this 
calculate method and the code calling it

```ruby
def calculate(op1, operator, op2)
string = op1.to_s + operator + op2.to_s
  # operator is assumed to be a string; make one big
  # string of it and the two operands
  eval(string)   # Evaluate and return a value
end

 @alpha = 25
 @beta = 12
 puts calculate(2, "+", 2)        # Prints 4
 puts calculate(5, "*", "@alpha") # Prints 125
 puts calculate("@beta", "**", 3) # Prints 1728
```


**You can even** have code that prompts the user for a method name and a single line of code
that afterwards defines the method and calls it.

```ruby
puts "Method name: "
meth_name = gets
puts "Line of code: "
code = gets

string = %[def #{meth_name}\n #{code}\n end] # Build a string
eval(string)                                 # Define the method
eval(meth_name)                              # Call the method
```

### Depending on the platform

In Ruby, definitions are executed. There is no “compile time,” and everything is dynamic rather 
than static. So if we want to make some kind of decision like this, we can simply evaluate a flag at runtime:

```ruby
if platform == Windows
  # action1
elsif platform == Linux
  # action2
else
  #default_action
end
```
\
Of course, there is a small runtime penalty for coding in this way because the flag may be tested many
times in the course of execution. But this example does essentially the same thing, enclosing the 
platform-dependent code in a method whose name is the same across all platforms:

```ruby
if platform == Windows
  def my_action
    action1 
  end
elsif platform == Linux
  def my_action
    action2 
  end
else
  def my_action
    default_action
  end
end
```