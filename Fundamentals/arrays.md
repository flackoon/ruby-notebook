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