## Hashes

### Creating a new hash

A new hash can be created [the same way an array is created](arrays.md####creating-an-array).

There is also a class method `new` that can take a parameter specifying a
**default** value. Note that this default value is actually **NOT part of the hash**.
It is simply a value returned in place of **nil**.

```ruby
d = Hash.new            # Creates an empty hash
e = Hash.new(99)        # Creates an empty hash
f = Hash.new("a" => 3)  # Creates an empty hash
e["angled"]             # 99
е.inspect               # {}
f["b"]                  # { "a" => 3 }
f.inspect               # {}
```

Finally there is a `to_h` method available to **Array** that converts an
array of two-element arrays into a hash of keys and values.

```ruby
g = [["a", 1]].to_h  # { "a" => 1 }
```

### Specifying a default value for a Hash

The default value of a hash is an object referenced in place of **nil**
This is useful if you plan to use methods with the hash value that are not
defined for nil. It can be assigned upon creation of the hash or at a later
time using the `default=` method.

> All missing keys point to the same default value object, so changing the
> default value of a hash has a **side effect**.

In contrast to **default**, a block can allow each missing key to have
its own default. A common idiom is a hash where the default value is an array,
so that items can be added without having to explicitly check for a value and
create an empty array:

```ruby
a = Hash.new { |h, key| h[key] = [] } # default value is a new []
a["hello"]          # []
a["good"] << "bye"  # { "good" => ["bye"] }
```

There is also an instance method called `fetch` that raises an **KeyError**
exception if the key doesn't exist in the **Hash** object. It takes a
second parameter that serves as a default value. Also fetch optionally
accepts a block to produce a default value in case the key is not found.
This is similar to default values created by a block.

```ruby
а = { "flat" => 3, "curved" => 2, "angled" => 5}
a.fetch("pointed")                  # KeyError
a.fetch("curved", "na")             # 2
a.fetch("x", "na")                  # "na"
a.fetch("flat") { |x| x.upcase }    # 3
a.fetch("pointed") { |x| x.upcase}  # "POINTED"
```

### Deleting Key-Value pairs

Use `clear` to remove all key-value pairs. This is essentially the same
as assigning a new empty hash but is **marginally faster**.

Use `shift` to remove the first key-value pair from a hash. This method
returns the removed pair as a two-element array or the default value of
the hash if it's empty.

Use `delete` to remove a specific key-value pair. It accepts a key and
returns the value if found. If not found the default value is returned.
It also accepts a block to produce a unique default value rather than 
just a reused object reference.

Use `delete_if`, `reject` or `reject!` in conjunction with the required
block to delete all keys for which the block evaluates to **true**. 
The method `reject` works with a copy of the hash and the method
`reject!` returns **nil** if no changes were made.

### Detecting keys and values in a Hash

To check if a key has been assigned you can use the `has_key?` method or
any of its **aliases**: `include?`, `key?`, `member?`.

You can also use `empty?` to see whether there are any keys in the hash
at all. 

To check if a value exists in an array, use the methods `has_value?` or 
`value?`.

### Extracting Hashes into Arrays

To convert an entire hash into an array, use the `to_a` method. It will
return an array with a generated two-element arrays in it for each key-value
pair.

```ruby
h = { "a" => 1, "b" => 2 }
h.to_a  # [["a", 1],  ["b", 2]]
```

It is also possible to convert only the keys or the values of the hash
to an array.

```ruby
h.keys      # ["a", "b"]
h.values    # [1, 2]
```

Finally, you can extract an array of values selectively based on a list
of keys using the `values_at` method. This works pretty much the same as for
arrays.

```ruby
h = { 1 => "one",  2 => "two", 3 => "three", 4 => "four", "cinco" => "five" }
h.values_at(3, "cinco", 4)    # ["three", "five", "four"]
```

### Selecting key-value pairs by criteria

> The [same that works for arrays](arrays.md#selecting-from-an-array-by-criteria), works here as well.

### Merging two Hashes

Ruby's `merge` method merges the entries of two hashes forming a third
new hash and overwriting any duplicates.

```ruby
dict = {"base" => "foundation", "pedestal" => "base"}
added = {"base" => "non-acid", "salt" => "NaCl"}
new_dict = dict.merge added
# {"base" => "non-acid", "pedestal" => "base", "salt" => "NaCL"}
```

An **alias** for `merge` is `update`.

You can also use their **in-place** variants to add the entries
of a given hash to another one.

If a block is specified, it can contain logic to deal with collisions.

```ruby
dict.merge! added { |key, old, new| old < new ? old : new }
```

### Creating a Hash from an Array

The easiest way to do create a hash from an array is with the `to_h` method
of an array of two-element arrays. It is also possible to use the bracket method
on the **Hash** class, with either two-element arrays or a single array with
an even number of elements

```ruby
pairs = [[2,3], [4,5], [6,7]]
array = [2,3,4,5,6,7]
h1 = pairs.to_h
h2 = Hash[pairs]
h3 = Hash[*array]
```

### The `inject` method

This method relies on the fact that frequently we will iterate through a 
list and "accumulate" a result that changes as we iterate. The most common
example might be finding the sum of a list of numbers. Whatever the operation,
there is usually an "accumulator" of some kind (for which we supply an initial
value) and a function or operation we apply (represented in Ruby as a block).

For trivial example or two, suppose that we have this array of numbers and we want 
to find the sum of all of them:

```ruby
nums = [3, 5, 7, 9, 11, 13]
sum = nums.inject(0) { |x, n| x + n }
```

> The **accumulator** value is optional. If omitted, the first item is
> used as the accumulator and is then omitted from iteration.

### Using Quantifiers

The quantifiers `any?` and `all?` make it easier to test the nature of a
collection. Each of these takes a block (which of course tests true or false).

```ruby
nums = [1, 3, 5, 8, 9]

# Are any of these numbers even?
flag1 = nums.any? { |x| x % 2 == 0 }    # true
# Are all of these numbers even?
flag2 = nums.all? { |x| x % 2 == 0 }    # false
```

If the block is omitted, these simply test the truth value of each element.

### The `partition` method

When `partition` is called and passed a block, the block is evaluated for each
element in the collection. The truth value of each result is then evaluated, and
a pair of arrays (inside another array) is returned. All the elements resulting in
true go in the first array; the others go in the second.

```ruby
nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]

odd_even = nums.partition { |x| x % 2 == 1 }
# [[1,3,5,7,9], [2,3,4,6,8]]
```

If we wanted to partition into more than two groups, we could use `group_by`,
which returns a hash, with one key for each result of the given block:

```ruby
nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]
mod3 = nums.group_by { |x| x % 3 }

# { 0 => [3, 6, 9], 1 => [1, 4, 7], 2 => [2, 5, 8]}
```

### Iterating by Groups

The iterator `each_slice` takes a parameter, **n**, and iterates over that
many elements at a time. If there are not enough items left to form a slice,  the
last slice will be smaller in size.

```ruby
arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
arr.each_slice(3) do |triple|
  puts triple.join(", ")
end

# Output:
# 1, 2, 3
# 4, 5, 6
# 7, 8, 9
# 10
```

### Converting to Arrays or Sets

Every **enumerable** can in theory be converted trivially to an array
(by using `to_a`). For example, a hash result in a nested array of pairs.

```ruby
hash = { 1 => 2, 3 => 4, 5 => 6 }
arr = hash.to_a  # [[5, 6], [1, 2], [3, 4]]
```

If the `set` library has been required, you can use the `to_set` method,
which works as expected (creates a set that in this case looks exactly the same
as the array generated earlier by the `to_a` method).

### Using Enumerator object

There is **external** and **internal** enumeration. In internal enumeration we simply
iterate over each item in the collection and execute the block for each item
in sequence; external iteration means that the code can grab the next item in 
the sequence "on demand".

```ruby
# External iteration
people = [2, "GEorge", "Washington",
          3, "Edgar", "Allan", "Poe",
          2, "John", "Glenn"]

enum = people.each # enum now holds an iterator object
loop do
  count = enum.next # Grab next item from array
  count.times { print enum.next }
  puts
end
```

The "magic" here is that when we try to take an item that isn't there,
we get a **nil** value, but something else happens. The enumerator raises a 
**StopIteration** exception, which is implicitly caught. If this happens other 
than in a loop, it should be caught explicitly. Otherwise, the program will terminate
with the exception.

There is a `rewind` method that "resets" the internal state to the beginning of the enumerable
sequence:

```ruby
list = [10, 20, 30, 40, 50]
enum = list.each
puts enum.next    # 10
puts enum.next    # 20
puts enum.next    # 30
enum.rewind
puts enum.next    # 10
```

There is also the `cycle` method, which can iterate over the collection more than once or
even "infinitely". The parameter specifies the number of cycles, defaulting to infinity.

```ruby
months = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
months.cycle(2) { |m| puts m }    # loops 24 times in all
months.cycle { |m| puts m }       # a true infinite loop
```

The `each_with_object` method works similarly to `inject`, but it conveniently returns
the same object passed into it. Thia avoids the situation in which you must explicitly 
return the accumulator at the end of the block, which is ugly.

```ruby
h = Hash.new(0)
result = [1,2,3,4].inject(h) { |acc, n| acc[n] += 1; acc }

h = Hash.new(0)
result = [1,2,3,4].each_with_object(h) do |n, acc|
  acc[n] += 1
end
```

### Searching and selecting

There is a method called `find_index`, which is the "generic" equivalent of an index
on an array (in fact, for an array, both these methods will return the same result). This
method will do a search for the first object equal to the one passed as a parameter and 
return the (zero-based) index for that object. 

```ruby
array = [10, 20, 30, 40, 50, 30, 20]
location = array.find_index(30)     # 2
```

Not every enumerable will necessarily be able to return a meaningful result
(for example, a set, which is unordered). In this case, **nil** will be returned.

The are also two quantifiers: `one?` and `none?`. The `one?` method is
easy to understand; the code block must evaluate to **true** exactly one for it
to return **true**.

```ruby
array = [1, 3, 7, 10, 15, 17, 21]
array.one? { |x| x % 2 == 0 }       # true (one even number)
array.one? { |x| x > 16 }           # false
[].one? { |x| true }                # empty array always returns false
```

But `none?` might be a little less intuitive. The rule is, it returns **true** if 
the block **never** evaluates to **true**.

If the code block is omitted, every item in the collection is tested for truth or
falsehood, and they must all test false for `none?` to return **true**.

### Extracting and Converting

An example is `take` and its companion `take_while`. These methods return a list of items
from the front of a collection. In this example, we start with a hash; each "item" in
the collection is a key-value pair, returned as a subarray. For another example we do these
same operations on arrays:

```ruby
hash = {1 => 2, 3 => 6, 4 => 8, 5 => 10, 7 => 14}
arr1 = hash.take(2)                   # [[1,2], [3,6]]
arr2 = hash.take_while {|k,v| v <= 8} # [[1,2], [3,6], [4,8]]
arr3 = arr1.take(1)                   # [[1,2]]
arr4 = arr2.take_while {|x| x[0] < 4} # [[1,2], [3,6]]
```

The `drop` method is complementary to `take`. It ignores (drops) items on the front of the 
collection and returns the remaining items. There is `drop_while` also.

The `reduce` method is also similar in spirit to `inject`. It applies a binary operation
(specified by a symbol) to each pair of items in the collection or it may take a block instead.
If an initial value is specified for the accumulator, it will be used; otherwise, the first value
in the collection will be used. So the basic variations are these:

```ruby
range = 3..6
# symbol
range.reduce(:*)                           # 3*4*5*6 = 360
# initial value, symbol
range.reduce(2, :*)                        # 2*3*4*5*6 = 720
# initial value, block    
range.reduce(10) {|acc, item| acc += item} # 10+3+4+5+6 = 28
# block
range.reduce {|acc, item| acc += item}     # 3+4+5+6 = 18
```

### Lazy Enumerators

More than just combining iterators, the **Enumarable** method `lazy` returns
a special type of **Enumerator** that calculates the next item only when it is requested.
This makes it possible to iterate over groups that are too big to store, like every odd 
number between 1 and infinity.

```ruby
enum = (1..Float::INFINITY).each 
lazy = enum.lazy    
odds = lazy.select(&:odd?)

odds.first(5)   # [1, 3, 5, 7, 9]
odds.next       # 1
odds.next       # 3
```

Ending a chain with `eager` generates a non-lazy enumerator, which is suitable
for returning or passing to another method that expects a normal enumerator.

Lazy enumerators provide some new ways to save memory and time while iterating
over big groups, so I encourage you to read the LazyEnumerator class
documentation.
