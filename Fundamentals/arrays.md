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

