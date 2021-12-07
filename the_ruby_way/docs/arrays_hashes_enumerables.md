# Arrays, Hashes, and Other Enumerables

1. [Array](#array)\
   1.1. [Creating an array](#creating-an-array)\
   1.2. [Accessing and assigning Array elements](#accessing-and-assigning-array-elements)\
   1.3. [Comparing arrays](#comparing-arrays)\
   1.4. [Sorting an Array](#sorting-an-array)\
   1.5. [Selecting from an Array by criteria](#selecting-from-an-array-by-criteria)\
   1.6. [Transforming or Mapping Arrays](#transforming-or-mapping-arrays)\
   1.7. [Removing nil values from an Array](#removing-nil-values-from-an-array)\
   1.8. [Removing specific Array elements](#removing-specific-array-elements)\
   1.9. [Concatenating and Appending to an Array](#concatenating-and-appending-to-an-array)\
   1.10. [Iterating over an Array](#iterating-over-an-array)\
   1.11. [Interposing delimiters to form a String](#interposing-delimiters-to-form-a-string)
2. [Hashes](#hashes)\
   2.1. [Creating a new hash](#creating-a-new-hash)\
   2.2. [Specifying a default value for a Hash](#specifying-a-default-value-for-a-hash)\
   2.3. [Deleting Key-Value pairs](#deleting-key-value-pairs)\
   2.4. [Detecting keys and values in a Hash](#detecting-keys-and-values-in-a-hash)\
   2.5. [Extracting Hashes into Arrays](#extracting-hashes-into-arrays)\
   2.6. [Selecting key-value pairs by criteria](#selecting-key-value-pairs-by-criteria)\
   2.7. [Merging two Hashes](#merging-two-hashes)\
   2.8. [Creating a Hash from an Array](#creating-a-hash-from-an-array)\
   2.9. [Using Quantifiers](#using-quantifiers)\
   2.10. [The partition method](#the-partition-method)\
   2.12. [Iterating by Groups](#iterating-by-groups)\
   2.13. [Converting to Arrays or Sets](#converting-to-arrays-or-sets)\
   2.14. [Using Enumerator object](#using-enumerator-object)\
   2.15. [Searching and selecting](#searching-and-selecting)\
   2.16. [Extracting and Converting](#extracting-and-converting)\
   2.17. [Lazy Enumerators](#lazy-enumerators)

## Array

### Creating an array

There are 3 ways to create a new array:

```ruby
a = Array.[](1,2,3,4)
b = Array[1,2,3,4]
c = [1,2,3,4]
```

There is also a class method `new` that takes 0, 1 or 2
parameters. The first one is the initial size of the array and the 
second one is the initial value of each of the elements

````ruby
d = Array.new             # []
c = Array.new(3)          # [nil, nil, nil]
# NOTE! All values in the produced array below are references to the same object
e = Array.new(3, "blah")  # ["blah", "blah", "blah"]
# To avoid this behavior use a block. The block will evaluate once for each element
f = Array.new(3) { "blah" }
````

Finally, the `Array()` method takes one argument and wraps it in an array
if necessary:
````ruby
g = Array(1)      # [1]
h = Array([1])    # [1]
i = Array(nil)    # [] nil is ignored
j = Array([nil])  # [nil] Arrays containing nil are left alone
````


### Accessing and assigning Array elements

This can be done with the well-know `[]` and `=[]` methods. Each can take 
an integer parameter, a pair of integers (start and end), or a range.
A negative integer counts backwards from the end of the array, starting at -1.

The special instance method `at` works like the simple case of element
reference. Because it can take only a single integer parameter it works 
slightly **faster**.

````ruby
a = [1,2,3,4,5,6]
b = a[0]
c = a.at(0)
d = a[-2]         # 5
e = a.at(-2)      # 5
f = a[9]          # 9
g = a[3, 3]       # [4,5,6]
h = a[2..4]       # [3,4,5]
j = a[2...4]      # [3,4]

a[-1] = 12        # [1,2,3,4,5,6,12]
````

A reference beyond the end of the array causes it to grow.

````ruby
k = [2,4,6,8,10]
k[1..2] = [3,3,3] # [2,3,3,3,8,10]
k[7] = 99         # [2,4,6,8,20,nil,99]
````

An array assigned to a single element would insert the array as a 
subarray.

````ruby
m = [1,2,3,4,5]
m[2] = [10,20,30] # [1,[10,20,30],3,4,5]
````

> The method `slice` is an alias for the method `[]`

The method `values_at` takes a list of indices and returns an array
consisting only of these elements.

```ruby
x = [10,20,30,40,50]
y = x.values_at(0,1,4)    # [10,20,50]
z = x.values_at(0..2, 4)  # [10,20,30,50]
```


### Comparing arrays

Comparison between arrays is tricky. Whenever you do it, do it with caution.

The instance method `<=>` is used to compare arrays.
It works as usual returning either -1 (less than), 0 (equal), 1 (greater than).
The methods `==` and `!=` depend on this method.

Arrays are compared in an "elementwise" manner; the first 2 elements
that are not equal determine the inequality of the whole comparison.

```ruby
a = [1,2,3,9,9] 
b = [1,2,4,1,1]
c = a <=> b       # -1 (meaning a < b) 
```

> Because the **Array** class does not mix in the **Comparable** module
> the usual operators `>, <, <= and >=` are not defined for arrays. You 
> can define these yourself easily though. 
> 
> An easier approach though would be 
> ```ruby
> class Array
>   include Comparable
> end
> ```


### Sorting an Array

The easiest way to sort an array is by using the built-in `sort` method.
It assumes the array is homogenous. If you try to sort a heterogenous array
that will raise an error.

The **Enumerable** module also has a `sort_by` method which applies
a function to the values and then sort based on the results.

```ruby
files = files.sort_by { |x| File.size(x) }
```

In the example above, each key is computed only once and is stored internally
as a part of a key/data tuple. Then the items in the array are sorted
based on the stored values returned by the block.

> For smaller arrays that might actually **decrease** effieciency, but might
> be worth a more readable code.

You can also do **multikey** sort by a number of attributes.

```ruby
list = list.sort_by { |x| [x.name, x.age, x.height] }
```

You are not limited to simple array elements like these. Any arbitrary
expression could be an array element.


### Selecting from an Array by criteria

The `detect` method will find at most a single element. It takes a block
and returns the first element for which the block evaluates to a value that
tests true.

```ruby
x = [5, 8, 12, 9, 4, 30]
# Find the first multiple of 6
x = x.detect { |e| e % 6 == 0 }  # 12
```

> The method `find` is a synonim of the `detect` method.

The methods `find_all` and `select` return multiple elements that 
match the given criteria.

```ruby
x.find { |e| e % 2 == 0 }       # 8
x.find_all { |e| e % 2 == 0 }   # [8, 12, 4, 30]
x.select { |e| e % 2 == 0 }     # [8, 12, 4, 30]
```

The `grep` method invokes the **relationship** operator to match
each element against the pattern specified (no need to be a RegExp). 
In its simplest form it returns an array with the matched elements 
in it. 

```ruby
a = %w[January February March April May]
a.grep(/ary/)         # ["January", "February"]
b = [1, 20, 5, 7, 13, 33, 15, 28]
b.grep(12..24)        # [20, 13, 15]
```

There is a block form that effectively transforms each result before 
storing it in the array; the resulting array contains the return values
of the block rather than the values passed to the block.

```ruby
# Let's store the length of the strings
a.grep(/ary/) { |e| e.length }  # [7, 8]
```

The `reject` method is complementary to `select`. It excludes each element
for which the block evaluates to **true**. The in-place mutator `reject!` is
also defined.

```ruby
c = [5, 8, 12, 9, 4, 30]
d = c.reject { |e| e % 2 == 0 }   # [5, 9]
c.reject! { |e| e % 3 == 0 }
# c is now [5, 8, 4]
```

The `min` and `max` methods may be used to find the minimum and maximum
values in an array. If used without a block, the "default" comparison is 
used, whatever that may be in the current situation (as defined by the 
`<=>` method). The second one takes a block and does a customized comparison.


### Transforming or Mapping Arrays

We use `collect` and `map` for mapping an array. 

```ruby
x = %w[alpha bravo charlie delta echo foxtrot]
# Get the initial characters
a = x.collect { |e| e[0] }   # %w[a b c d e f]
a = x.map { |e| e[0] }       # %w[a b c d e f]
```

The **in-place** variant `collect!` (or `map!`) is also defined.

```ruby
x.collect! { |e| e.upcase } 
# x is now %w[ALPHA BRAVO CHARLIE DELTA ECHO FOXTROT]
```


### Removing **nil** values from an Array

The `compact` method (or its **in-place** version `compact!`) removes **nil**
values from array, leaving the rest untouched.

```ruby
a = [1, 2, 3, nil, 4, nil, 5]
b = a.compact  # [1, 2, 3, 4, 5]
a.compact!     # a is now [1, 2, 3, 4, 5]
```


### Removing specific Array elements

If you want to delete an element at a **specific index** you can use
the `delete_at` method.

If you want to delete all instances of a certain piece of data, `delete` will
do the job. It returns the value of the object deleted or **nil** if it wasn't
found. 

> The `delete` method also accepts a block; all that happens is that the block
> is evaluated (potentially performing a wide range of operations) if the object
> is not found and the value of the block is returned.

The `delete_if` method passes every element into the supplied block
and deletes if only if the block evaluates to **true**. It behaves similarly
to `reject!`, except that the latter can return **nil** when the array
remains unchanged.

```ruby
email = ["job offers", "greetings", "spam", "news items"]
# Delete four-letter words
email.delete_if { |x| x.length == 4 }
# email is now ["job offers", "greetings", news items"]
```

The `slice!` method accesses the same elements as `slice` but deletes
them from the array as it returns their values.

```ruby
x = [0, 2, 4, 6, 8, 10, 12, 14, 16]
a = x.slice! 2        # 4
# x is now [0, 2, 6, 8, 10, 12, 14, 16]
b = x.slice!(2, 3)    # [6, 8, 10]
# x is now [0, 2, 12, 14, 16]
```

The `shift` and `pop` methods can be used to delete elements from the
beginning or the end of an array.


### Concatenating and Appending to an Array

The "append" operator (`<<`) appends an object onto an array. The return
value is the array itself, so that those operations can be **chained**.

```ruby
x = [1,2,3]
x << 13       # x is now [1, 2, 3, 13]
x << 17 << 21 # x is now [1, 2, 3, 13, 17, 21]
```

Similar to the append operator are the `unshift` and `push` methods, which add
to the beggining and end of an array.

```ruby
x = [1, 5, 9]
x.push *[2, 6, 10]   # x is now [1, 5, 9, 2, 6, 10]
x.unshift 3          # x is now [3, 1, 5, 9, 2, 6, 10]
```

> Arrays may be concatenated with the `concat` method or by using the
> `+` and `+=` operators. But bear in mind that all 3 of these methods
> create a new array object.\
>
> Also bear in mind that while `<<` adds to an existing array, it appends
> a new array element. ```[1,2] << [3,4] will result in [1,2, [3,4]]```. For
> occasions like this, you can use the spread (`*`) operator.


### Iterating over an Array

The standard iteartor `each` is expectedly available here. 

The `reverse_each` method iterates in a reverse order. It is equivalent
to using `reverse` and then `each` but is faster.

If you wanto to iterater over the **indicies** of an array, you can
use the `each_index` method.

The chainable iterator `with_index` adds the element index to an 
existing iterator.

```ruby
x = ["alpha", "beta", "gamma"]
x.each.with_index do |value, index|
  puts "Element: #{value} at index #{index}"
end
```


### Interposing delimiters to form a String

You can join the elements of an array into a string with a delimiter
by using the well-known `join` method or  the `*` operator.

```ruby
been_there = ["Veni", "vidi", "vici."]
journal = been_there * ", "     # "Veni, vidi, vici."
```

### Removing duplicate values from an array

This can be done using the `uniq` method (or its **in-place** variant `uniq!`).

### Interleaving Arrays

Suppose that we wanted to take two Arrays and "interleave" them so that
the new array contains an array of paired elements for each of the two
original ones. That's what the `zip` method in **Enumerable** does.

```ruby
a = [1, 2, 3, 4]
b = ["a", "b", "c", "d"]
c = a.zip b
# c is now [[1, "a"], [2, "b"], ...]
```

> You can use `flatten` to eliminate the nesting in an array.

If a **block** is specified, the output arrays will be passed successively
into the block:

```ruby
a.zip b {|x1, x2| puts "#{x2} - #{x2}"}
# Prints:  a - 1
#          b - 2
#          c - 3
#          d - 4
# and returns nil
```


## Hashes

### Creating a new hash

A new hash can be created [the same way an array is created](Desktop/RubyExercise/docs/arrays.md####creating-an-array).

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

> The [same that works for arrays](Desktop/RubyExercise/docs/arrays.md#selecting-from-an-array-by-criteria), works here as well.


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
