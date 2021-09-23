## Working with String

### Delayed interpolation of Strings

There's no perfect way to do this.\
A naive approach is to store a single-quoted string and then evaluate it:

```ruby
str = '#{name} is my name, and #{nation} is my nation'
name, nation = "Stephen Dedalus", "Ireland"
s1 = eval('"' + str + '"')
```

However, using `eval` is almost always the **worst** option. Any time you see `eval`, you are opening
yourself up to many problems, including **extremely slow execution** and unexpected **security 
vulnerabilities**, so it should be **avoided** if at all possible.

A much less dangerous way is to use a **block**:
```ruby
str = Proc.new do |name, nation|
  "#{name} is my name, and #{nation} is my nation"
end
s2 = str.call("Gulliver Foyle", "Terra")
```

## Converting to Numbers

Basically there are 2 ways to convert to numbers: the **Kernel** method **Integer** and *Float** 
and the `to_i` and `to_f` methods of **String**.

The simple case is trivial, and these are equivalent:

```ruby
x = "123".to_i        # 123
y = Integer("123")    # 123
```

When a string is **not** a valid number, however, their behavior differ:

```ruby
x = "junk".to_i       # silently returns 0
y = Integer("junk")   # error
```

> `to_i / to_f` stops converting  when it reaches a non-numeric character, but **Integer/Float** raises an error.
3