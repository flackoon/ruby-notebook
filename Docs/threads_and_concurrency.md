# Threads and Concurrency

1. [Creating and Manipulating Threads](#creating-and-manipulating-threads)\
  1.1. [Creating Threads](#creating-threads)\
  1.2. [Accessing Thread-Local Variables](#accessing-thread-local-variables)\
  1.3. [Querying and Changing Thread Status](#querying-and-changing-thread-status)\
  1.4. [Achieving a Rendezvous (and Capturing a Return Value)](#achieving-a-rendezvous-and-capturing-a-return-value)\
  1.5. [Dealing with Exceptions](#dealing-with-exceptions)\
  1.6. [Using a Thread Group](#using-a-thread-group)
2. [Synchronizing Threads](#synchronizing-threads)\
  2.1. [Using a Thread Group](#using-a-thread-group)


A _thread_ generally lives inside a process, sharing its address space and open files. The good news about threads is
that because they do share so much with their parent process, they are relatively cheap to create. 

Threads are useful in circumstances where separate pieces of code naturally function independently of each other. On the
other hand, there are some potential disadvantages in the use of threads. Switching between threads can reduce the speed
at which each individual task runs. In some cases, access to a resource is inherently serialized so that threading doesn't
help. Sometimes, the overhead of synchronizing access to resources exceeds the savings due to multithreading.

The difficulties associated with unsynchronized threads are well known. A data structure can be corrupted by threads 
attempting simultaneously access to the data. **Race conditions** may occur wherein one thread makes some assumption about
what another has done already; these commonly result in "nondeterministic" code that may run differently with each execution.
Finally, there is the danger of deadlock, wherein no thread can continue because it is waiting for a resource held by some
other thread, which is also blocked. Code written to avoid these problems is referred to as **_thread-safe_** code.

## Creating and Manipulating Threads

### Creating threads

Creating a thread in Ruby is easy. Simply call the `new` method and attach a block that will be the body of the thread.
The method `fork` is an alias for `new`.

```ruby
thread = Thread.new do 
  # Statements comprising the thread..
end
```

If you want to pass parameters into your thread, you can do so by passing them into `Thread.new`:

```ruby
thread2 = Thread.new(99, 100) do |a, b|
  # a is a parameter that starts out equal to 99
  # b is also a parameter that starts out equal to 100
end
```

Because threads are built around ordinary code blocks, they can also access variables from the scope they were created in. 

### Accessing Thread-Local Variables

You can treat a thread instance like a hash, setting and getting values by key. This thread-local data can be accessed from
both inside and outside of the thread and provide a convenient sharing mechanism between the two. 

```ruby
thread = Thread.new do
  t = Thread.current
  t[:var1] = "This is a string"
  t[:var2] = 365
end

sleep 1 # Let the thread spin up

# Access the thread-local data from outside
x = thread[:var1]   # This is a string

has_var1 = thread.key? :var2  # true
```

Note that thread-local data is _not_ the same as the local variables inside the thread block.
The local variable `var3` and `thread[:var3]` may look somewhat alike, but they are definitely
not the same:

```ruby
thread = Thread.new do
  t = Thread.current
  t["var3"] = "thread local!!"
  var3 = "a regular local"
end

sleep 1 

a = thread[:var3]   # "thread local!!"
```

> Although threads with their thread-local data act like hashes, they are definitely **not** the real thing.
> They lack most of the familiar **Enumerable** methods. Threads are picky about the keys you are allowed to
> use for thread-local data. Besides symbols, your only other choice for a thread local key is a string, and 
> even then it gets silently converted to a symbol.

### Querying and Changing Thread Status

The **Thread** class supports a number of useful class methods for managing threads. For example,
the `list` method returns an array of all living threads, whereas the `main` method returns a 
reference to the main thread, the one that kicks everything off. And there is the `current` method
that allows a thread to find its own identity.

```ruby
t1 = Thread.new { sleep 100 }

t2 = Thread.new do
  if Thread.current = Thread.main
    puts "This is the main thread"  # Does NOT print
  end
  1.upto(100) { sleep 0.1 }
end

count = Thread.list.size  # 3

if Thread.list.include? Thread.main
  puts "Main thread is alive" # Always prints
end

if Thread.current = Thread.main
  puts "I'm the main thread"    # Prints
end
```

The `exit`, `pass`, `start`, `stop` and `kill` methods are used to control the execution of threads, 
either from inside or outside.

```ruby
Thread.kill(t1)         # Kill thread t1 from the prev example
Thread.pass             # Give up my timeslice
t3 = Thread.new do
  sleep 20
  Thread.exit           # Exit the current thread
  puts "Can't happen"   # Never reached
end

Thread.kill(t2)         # Now kill t2

# Exit the main thread (killing any others)
Thread.exit
```

There are also various methods for checking the state of a thread. The instance method
`alive?` will tell whether the thread is "living", and `stop? will return `true` if a thread is either
dead or sleeping. Both will return `true` if the thread is sleeping.

To get a complete picture of where a thread is in its life cycle, use the `status` method. Possible return
values are something of a hodgepodge: If the thread is currently running, status will be `run`; if it is
stopped, sleeping, or waiting on I/O status is `sleep`. If it terminated normally, you will get `false` back
from `status`. If the thread died horribly with an exception, status will be `nil`.

Threads are also aware of the `$SAFE` global variable; but when it comes to threads, `$SAFE` is not quite
as global as it seems because each thread effectively has its own. **Thread** instances have a `safe_level`
method that returns the safe level for that particular thread.

```ruby
t1 = Thread.new { $SAFE = 1; sleep 5 }
sleep 1
level = Thread.main.safe_level # 0
level_t1 = t1.safe_level       # 1
```

Ruby threads have a numeric priority. It can be changed with the `priority` accessor:

`t1.priority = 3`

The special method `pass` is used when a thread wants to yield control to the scheduler.
A thread that calls `pass` merely yields its current timeslice; it doesn't actually stop
or go to sleep:

```ruby
t1 = Thread.new do
  Thread.pass
  puts "First thread"
end

t2 = Thread.new do
  puts "Second thread"
end

sleep 3 # Give the threads a change to run.
```

In this contrived example, it is more likely to see the second thread print before the first. If we take out
the call to `pass`, we are a bit more likely to see the first thread – which started first – win the race.
Of course, there are no guarantees. The `pass` method and thread priorities are there to provide _hints_ to the
scheduler, not to keep your threads synchronized.

A thread that is stopped may be awakened by use of the `run` or `wakeup` method.

The difference between these is that the `wakeup` call will change the stat of the thread so that it is runnable
but will not schedule it to be run; on the other hand, `run` will wake up the thread and schedule it for immediate
running.

### Achieving a Rendezvous (and Capturing a Return Value)

Sometimes one thread wants to wait for another to finish. The instance method `join` will accomplish this.

```ruby
t1 = Thread.new { do_something_long }
do_something_brief
t1.join # Don't continue until t1 is done
```

Another useful little `join` idiom is to wait for all the other living threads to finish:

```ruby
Thread.list.each { |t| t.join if t!= Thread.current }
```

> It is an error for any thread, even the main one, to call `join` on itself. That's why you have to check.

As seen, every thread has an associated block. Elementary Ruby knowledge tells that a block can have a return
value. This implies that a thread can return a value. The `value` method will implicitly perform a join operation
and wait for the thread to complete; then it will return the value of the last evaluated expression.

```ruby
t = Thread.new do
  sleep 0.2
  42
end

puts "The secret is #{t.value}"
```

### Dealing with Exceptions

Under normal circumstances, an exception inside a thread will not raise in the main thread.
Exceptions inside threads are not raised until the `join` or `value` method is called on the thread.
It is up to some other thread to check on the thread that failed and report the failure.

```ruby
t1 = Thread.new do
  raise "Oh no!"
  puts "This will never print"
end

begin
  t1.status # nil, indicating an exception occured
  t1.join
rescue => e
  puts "Thread raised #{e.class}: #{e.message}"
end
```

> When debugging threaded code, it can sometimes be helpful to use the `abort_on_exception` flag. When it is set
> to `true`, uncaught exceptions will terminate _all_ running threads.

Note that setting `abort_on_exception` on a global level is suitable for development or debugging because it is 
equivalent to `Thread.list.each(&:kill)`. The `kill` method is (ironically) not thread-safe. Only use `kill` or
`abort_on_exception` to terminate threads that are definitely safe to abruptly kill. Aborted threads can hold a 
lock or be prevented from running clean-up code in an `ensure` block, which can leave your program in an 
unrecoverable state.

### Using a Thread Group

A thread group is a way of managing threads that are logically related to each other.
Normally all threads belong to the **Default** thread group. However, you can create thread groups of your own
and add threads to them. A thread can only be in one thread group at a time so that wen a thread is added to a
thread group, it is automatically removed from whatever group it was in previously.

The `ThreadGroup.new` class method will create a new thread group, and the `add` instance method will add a thread
to the group:

```ruby
t1 = Thread.new("file1") { sleep(1) }
t2 = Thread.new("file2") { sleep(2) }

threads = ThreadGroup.new
threads.add t1
threads.add t2
```

The instance method `list` will return an array of all the threads in a thread group.

**ThreadGroup** instances also feature the oddly named `enclose` method, which mostly prevents new threads from being
added to the group. We say "mostly" because any new threads started from a thread already in an enclosed group will still 
be added to the group. Threads also have an `enclosed?` instance method that will return `true` if the group has in fact 
been enclosed.

> When a thread dies in a thread group, it is silently removed from the group it is in. So just because you stick
> threads in a group does not mean they will all be there ten minutes or ten seconds from now.

## Synchronizing Threads

Why is synchronization necessary? It is because the "interleaving" of operations causes variables and other entities
to be accessed in ways that are not obvious from reading the code of the individual threads. Two or more threads 
accessing the same variable may interact with each other in ways that are unforeseen and difficult to debug.

```ruby
def new_value(i)
  i + 1
end

x = 0

t1 = Thread.new do
  1.upto(1000000) { x = new_value(x) }
end

t2 = Thread.new do
  1.upto(1000000) { x = new_value(x) }
end

t1.join
t2.join

puts x

# The end value of "x" should be two million right? 
# Well, when this is run on JRuby, the results are even more unexpected: 1143345 on one run, followed by
# 1077403 on the next and 1158422 on a third. Is this a terrible bug in Ruby?
# 
# Not really. The code assumes that the incrementing of an integer is an atomic(or invisible) operation.
# But it isn't.
```

> MRI's ability to sometimes produce the correct result might lead a casual observer to think this code is
> thread-safe. THe problem is hidden as a side effect of MRI's GIL, or **Global Interpreter Lock**, which ensures
> that only one thread can run at a time. As you just saw, even with the GIL, MRI suffers from the same synchronization
> problem and can still produce wrong result.



