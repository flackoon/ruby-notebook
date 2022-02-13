# Getting the Most out of Core Classes

- [Learning when to use core classes](#learning-when-to-use-core-classes)
- [Best uses for true, false, and nil objects](#best-uses-for-true-false-and-nil-objects)
- [Different number types for different needs](#different-number-types-for-different-needs)
- [Understanding how symbols differ from strings](#understanding-how-symbols-differ-from-strings)

## Learning when to use core classes

> A good general principle is to only create custom classes when the benefits outweigh the costs.

With core classes, your code is often more intuitive, and in general will perform better, since using core classes directly
results in less indirection.

With custom classes, you are able to encapsulate your logic, which can lead to more maintainable code in the long term,
if you have to make changes.

If you aren't sure whether to use a custom class or a core class, a good general principle is to start with the use of
core classes, and only add a custom class when you see a clear advantage in doing so.

## Best uses for true, false, and nil objects

Most Ruby methods ending with `?` should return **true** or **false**. In general, the Ruby core methods use the following
approach:

```ruby
1.kind_of?(Integer)
# => true
```

The **nil** object is conceptually more complex than either **true** or **false**. As a concept, **nil** represents the
absence of information. **nil** should be used whenever there is no information available, or when something requested
cannot be found. **nil** is sort of the opposite of everything that's not true or false.

> In general, if you have a Ruby method that returns **true** in a successful case, it should return **false** in the
unsuccessful case. If a method returns an object that is not **true** or **false** in a successful case, it should
return **nil** in the unsuccessful case (or raise an exception).

Ruby's core classes also use **nil** as a signal that a method that modifies the receiver did not make a modification.

```ruby
"a".gsub!('b', '')
# => nil
```

The reason for this behavior is optimization, so if you only want to run code if the method modified the object, you
can use a conditional:

```ruby
string = "..."
if string.gsub!('a', 'b')
  # string was modified
end
```

The trade-off here is that you can no longer use these methods in method chaining. Ruby chooses a trade-off that allows
higher performance but sacrifices the ability to method chain. If you want to safely method chain, you need to use
methods that return new objects, which are going to be slower as they allocate additional objects that need to be
garbage collected.

Be aware that when using **nil** and **false** in Ruby you cannot use the simplest approach of using the `||=` operator
for memoization.

```ruby
@cached_value ||= some_expression
```

If **some_expression** returns **nil** or **false** value, the calling will continue until it returns a truthy value.
When you want to cache an expression that may return falsey value as a valid value, you need to use a different approach.

For instance variables, the simplest, although more verbose:

```ruby
if defined?(@cached_value)
  @cached_value
else
  @cached_value = some_expression
end
```

If you are using a hash to store multiple cached values:

```ruby
cache.fetch(:key) { cache[:key] = some_expression }
```

One advantage of using **true**, **false**, and **nil** is they are of the immediate object types – they don't require
memory allocation, and as such they are generally faster than non-immediate objects.

## Different number types for different needs

... in Ruby integers division works as in C, returning only the quotient and dropping any remainder.
If you are considering using division in your code and both arguments could be integers, you can convert the numerator
to a different numeric type, so that the division operation will include the remainder.

```ruby
5 / 10r # Or Rational(5, 10) or 5 / 10.to_r
# => (1/2)
```

In cases where your numeric type needs to include a fractional component, you have 3 main choices: floats, rationals, or
BigDecimal, each with its own trade-offs:
- floats are fastest but not exact in many cases
- rationals are exact but not as fast
- BigDecimal is exact in most cases, but is generally the slowest

> Rationals are about 2-6 times slower than floats, depending on what calculations you are doing. So, do not avoid the use
> of rationals on a performance basis unless you have profiled them and determined they are the bottleneck.

A good general principle is to use a rational whenever you need to do calculations with non-integer values and you need
exact answers. For cases where exactness isn't important, or you are only doing comparisons between numbers and not
calculations that result in an accumulated error, it is probably better to use floats. For BigDecimal – you should use it
only when dealing with other systems that support similar types, such as fixed precision numeric types in many databases,
or when dealing with other fixed precision areas such as monetary calculations.

## Understanding how symbols differ from strings

A symbol in Ruby is a number with an attached identifier that is a series of characters or bytes. Symbols in Ruby are an
object wrapper for an internal type that Ruby calls _ID_, which is an integer type. When you use a symbol, Ruby looks up
the number associated with that identifier. The reason for having an _ID_ type internally is that it is much faster for
computers to deal with integers.

> It is better for performance to use symbols, which is Ruby's representation of an _ID_, as opposed to a string, which
> Ruby must perform substantial work on to convert to an _ID_.

The general principle here is to be like Ruby, and use symbols when you need an identifier in your code, and strings
when you need text or data.

## Learning how best to use arrays, hashes, and sets

### Implementing an in-memory database

See the code example [in_memory_db](../snippets/in_memory_db.rb).


## Working with Struct - one of the underappreciated core classes

The **Struct** class is one of the underappreciated Ruby core classes. It allows you to create classes with one or more
fields, with accessors automatically created for each field.

```
class Artist
  attr_accessor :name, :albums

  def initialize(name, albums)
    @name = name
    @albums = albums
  end
end
```

Instead of that, you can write a small amount of Ruby code, and have the initialize and accessor automatically created:

```ruby
Artist = Struct.new(:name, :albums)
```
