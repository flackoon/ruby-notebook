# Advanced Data Structures

1. [Working with Sets](#working-with-sets)\
   1.1. [Simple Set operations](#simple-set-operations)\
   1.2. [More advanced Set operations](#more-advanced-set-operations)
2. [Working with Stacks and Queues](#working-with-stacks-and-queues)\
   2.1. [Implementing a stricter Stack](#implementing-a-stricter-stack)\
   2.2. [Implementing stricter Queues](#implementing-stricter-queues)\
   2.3. [Implementing a Binary Tree](#implementing-a-binary-tree)\
   2.4. [Sorting using a Binary Tree](#sorting-using-a-binary-tree)

## Working with Sets

To use the **Set** class we need to require it:

```ruby
require 'set'
```

This also adds a `to_set` method to **Enumerable** so that any enumerable
object can be converted to a set.

Creating a new set is easy. The `[]` method works much as it does for hashes.
The **new** method takes an optional enumerable object and an optional block.
If the block is specified, it is used as a kind of "preprocessor" for the list
(like a map operation):

```ruby
s1 = Set[3, 4, 5]              # {3, 4, 5} in math notation
arr = [3,4,5]
s2 = Set.new(arr)              # same
s3 = Set.new(arr) {|x| x.to_s} # set of strings, not numbers
```


### Simple Set operations

The binary set operators don't have to have a set on the **right** side. Any **enumerable**
will work, producing a **set** as a result.

Membership is tested with `member?` or `include?`, as with arrays. Remember the
operands are "backwards" from mathematics.

We can test for the null or empty set with `empty?`, as we would an array. The `clear`
method will empty a set regardless of its current contents.

We can test the relationship of two sets: Is the receiver a subset of the other set? Is it
a proper subset (a proper subset is a subset that is not equal to the given set) ? 
Is it a superset?

```ruby
x = Set[3,4,5]
y = Set[3,4]

x.subset?(y)        # false
y.subset?(x)        # true
y.proper_subset?(x) # true
x.subset?(x)        # true
x.proper_subset?(x) # false
x.superset?(y)      # true
```

The `add` method (alias `<<`) adds a single item to a set, normally returning its own
value; `add?` returns **nil** if the item is already there. The `merge` method is useful for adding
several items at once. All these potentially modify the receiver, of course. The `replace`
method acts as it does for a string or array.

Finally, two sets can be tested for equallity in an intuitive way:

```ruby
Set[3,4,5] == Set[5,4,3]  # true
```


### More advanced Set operations

It's possible to iterate over a set, but (as with hashes) do not expect a sensible 
ordering because sets are inherently unordered, and Ruby does not guarantee a sequence.
(You may even get consistent, unsurprising results at times, but it is unwise to depend
on that fact.)

```ruby
s = Set[1,2,3,4,5]
puts s.each.first   # may output any set member
```

The `classify` method is like a multiway `partition` method; in other words, it is the
rough equivalent of the **Enumerable** method called `group_by`.

```ruby
files = Set.new(Dir["*"])
hash = files.classify do |f|
  if File.size(f) <= 10_000
    :small
  elsif File.size(f) <= 10_000_000
    :medium
  else
    :large
  end
end

big_files = hash[:large]  # big_files is a Set
```

The `divide` method is similar, but it calls the block to determine "commonality" of
items, and it results in a set of sets.

If the arity of the block is 1, it will perform calls of the form `block.call(a) == block.call(b)`
to determine whether **a** and **b** belong together in a subset. If the arity is 2, it will perform
calls of the form `block.call(a, b)` to determine whether these 2 items belong together.

For example, the following block (with arity 1) divides the set into two sets, one containing
the even numbers and one containing the odd ones.

```ruby
require 'set'
numbers = Set[1,2,3,4,5,6,7,8,9,0]
set = numbers.divide{|i| i % 2}
p set  # #<Set: {#<Set: {1,3,5,7,9}>, #<Set: {2,4,6,8,0}>}>
```

Here's another contrived example. Twin primes are prime numbers that differ by 2 (such as
11 and 13); singleton primes are the ones (such as 23). The following example separates these 
two groups, putting pairs of twin primes in the same set with each other.
This example uses a block with arity 2:

```ruby
primes = Set[2,3,5,7,9,11,13,17,19,23,29,31]
set = primes.divide{|i,j| (i-j).abs == 2}
# set is #<Set: { #<Set: {2}>, #<Set: {3,5,7}>, 
# #<Set: {11, 13}>, #<Set: {17,19}>, #<Set: {23}>, #<Set: {29,31}>}>
```

> As said in the previous section, it's important to realize that the **Set** class
> doesn't always insist that a parameter or operand has to be another set. In fact,
> most of these methods will take _any enumerable object_ as an operand. Consider this a feature.

## Working with Stacks and Queues

### Implementing a stricter Stack

```ruby
class Stack
  def initialize
    @store = []
  end
  
  def push(x)
    @store.push x
  end
  
  def pop
    @store.pop
  end
  
  def peek
    @store.last
  end
  
  def empty?
    @store.empty?
  end
end
```


### Implementing stricter Queues

This class implements a queue for the simple benefit of not accessing such a data structure
illegally, as with the Stack.

```ruby
class Queue
  def initialize
    @store = []
  end
  
  def enqueue(x)
    @store << x
  end
  
  def dequeue
    @store.shift
  end
  
  def peek
    @store.first
  end
  
  def length
    @store.length
  end
  
  def empty?
    @store.empty?
  end
end
```

As mentioned, the **Queue** class in the thread library is needed in threaded code, because
it is thread-safe. It is accompanied by a **SizedQueue** variant that is also thread-safe.

### Implementing a Binary Tree

```ruby
class Tree
  attr_accessor :left
  attr_accessor :right
  attr_accessor :data

  def initialize(x=nil)
    @left = nil
    @right = nil
    @data = x
  end
  
  def insert(x)
    list = []
    if @data == nil
      @data = x
    elsif @left == nil 
      @left = Tree.new(x)
    elsif @right == nil 
      @right = Tree.new(x)
    else
      list << @left
      list << @right
      loop do
        node = list.shift
        if node.left == nil
          node.insert(x)
          break
        else 
          list << node.left
        end
        if node.right == nil 
          node.insert(x)
          break
        else
          list << node.right
        end
      end
    end
  end
  
  def traverse()
    list = []
    yield @data
    list << @left if @left != nil 
    list << @right if @right != nil
    loop do
      break if list.empty?
      node = list.shift
      yield node.data
      list << node.left if node.left != nil
      list << node.right if node.right != nil
    end
  end
end

items = (1..7).to_a
tree = Tree.new
items.each{|x| tree.insert(x)}
tree.traverse {|x| print "#{x}"}
puts
# Prints "1 2 3 4 5 6 7"
```

### Sorting using a Binary Tree

```ruby
class Tree
  attr_accessor :left
  attr_accessor :right
  attr_accessor :data

  def initialize(x=nil)
    @left = nil
    @right = nil
    @data = x
  end
  
  def insert(x)
    if @data == nil 
      @data = x
    elsif x <= @data
      if @left == nil
        @left = Tree.new x
      else
        @left.insert x
      end
    else
      if @right == nil
        @right = Tree.new x
      else
        @right.insert x
      end
    end
  end
  
  def inorder()
    @left.inorder {|y| yield y } if @left != nil
    yield @data
    @right.inorder {|y| yield y} if @right != nil
  end
  
  def preorder() 
    yield @data
    @left.preorder {|y| yield y } if @left != nil
    @right.preorder {|y| yield y } if @right != nil
  end
  
  def postorder()
    @left.postorder {|y| yield y} if @left != nil 
    @right.postorder {|y| yield y} if @right != nil
    yield @data
  end
end

items = [50, 20, 80, 10, 30, 70, 90, 5, 14,
         28, 41, 66, 75, 88, 96]

tree = Tree.new

items.each {|x| tree.insert(x)}

tree.inorder { |x| print x, " "}
puts
tree.preorder { |x| print x, " "}
puts
tree.postorder { |x| print x, " "}
puts

# Output:
# 5 10 14 20 28 30 41 50 66 70 75 80 88 90 96
# 50 20 10 5 14 30 28 41 80 70 66 75 90 88 96
# 5 14 10 28 41 30 20 66 75 70 88 96 90 80 50
```

