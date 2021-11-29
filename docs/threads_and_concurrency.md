# Threads and Concurrency

1. [Creating and Manipulating Threads](#creating-and-manipulating-threads)\
  1.1. [Creating Threads](#creating-threads)\
  1.2. [Accessing Thread-Local Variables](#accessing-thread-local-variables)\
  1.3. [Querying and Changing Thread Status](#querying-and-changing-thread-status)\
  1.4. [Achieving a Rendezvous (and Capturing a Return Value)](#achieving-a-rendezvous-and-capturing-a-return-value)\
  1.5. [Dealing with Exceptions](#dealing-with-exceptions)\
  1.6. [Using a Thread Group](#using-a-thread-group)
2. [Synchronizing Threads](#synchronizing-threads)\
  2.1. [Performing Simple Synchronization](#performing-simple-synchronization)\
  2.2. [Synchronizing Access with a Mutex](#synchronizing-access-with-a-mutex)\
  2.3. [Using the Built-in Queue Classes](#using-the-built-in-queue-classes)\
  2.4. [Using Condition Variables](#using-condition-variables)\
  2.5. [Other Synchronization Techniques](#other-synchronization-techniques)\
  2.6. [Setting a Timeout for an Operation](#setting-a-timeout-for-an-operation)\
  2.7. [Waiting for an Event](#waiting-for-an-event)\
  2.8. [Collection Searching in Parallel](#collection-searching-in-parallel)
3. [Fibers and Cooperative Multitasking](#fibers-and-cooperative-multitasking)


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


### Performing Simple Synchronization

The simplest form of synchronization is to use `Thread.exclusive`. That method defines a critical section of code: Whenever
one thread is in a critical section, no other threads will run.

Using `Thread.exclusive` is easy: You simply pass in a block. Ruby will ensure that no other thread is running while the code
in the block is executed. In the following code, we revisit the previous example and use the `Thread.exclusive` method to define
the critical section and protect the sensitive parts of the code:

```ruby
def new_value(i)
  i + 1
end

x = 0

t1 = Thread.new do
  1.upto(1000000) do
    Thread.exclusive { x = new_value(x) }
  end
end

t2 = Thread.new do
  1.upto(1000000) do
    Thread.exclusive { x = new_value(x) }
  end
end

t1.join
t2.join

puts x
```

In practice, using `Thread.exclusive` presents a number of problems, the key one being just how expensive its effects are. Using it
means that you are blocking _almost all_ other threads, including the innocent ones that will never touch any of your precious data.

The _almost_ touches on another problem: Although `Thread.exlcusive` is expansive, it is not completely airtight. There are circumstances
under which another thread can run even while a `Thread.exclusive` block is under way. For example, if you start a second thread inside
your exclusive block, _that thread will run_.


### Synchronizing Access with a Mutex

One such tool is the mutex (short for mutual exclusion). To see Ruby's mutex in action, let's rework our last counting example to use one:

```ruby
require 'thread'

def new_value(i); i + 1; end

x = 0
mutex = Mutex.new

t1 = Thread.new do
  1.upto(1000000) do
    mutex.lock
    x = new_value(x)
    mutex.unlock
  end
end

t2 = Thread.new do
  # Same thing as in t1
end

# join threads, print X
```

> Instances of the **Mutex** class provide a sort of privately scoped synchronization: **Mutex** ensures that
> only one thread at a time can call `lock`. If two threads happen to call `lock` at about the same time, one of the
> threads will be suspended until the lucky thread – the one that got the lock – calls `unlock`. Because any given 
> mutex instance only affects the threads that are **trying to call `lock` for that instance**, we can have our synchronization
> without making all but one of our threads come to a halt.

There's also the `try_lock` method that acts just like `lock`, except that it doesn't block: If another thread already has
the lock, `try_lock` will return `false` immediately.

This feature is useful any time a thread doesn't want to be blocked. **Mutex** instances also have a `synchronize` method
that takes a block:

```ruby
x = 0
mutex = Mutex.new

t1 = Thread.new do
  1.upto(1000000) do
    mutex.synchronize { x = new_value(x) }
  end
end
```

Finally, there is also a `mutex_m` library defining a **Mutex_m** module, which can be mixed into a class (or used to
extend an object). Any such extended object has the mutex methods so that the object itself can be treated as a mutex.

```ruby
require 'mutex_m'

class MyClass
  include Mutex_m
  
  # Now any MyClass instance can call
  # lock, unlock, synchronize...
  # or external objects can invoke these methods on
  # a MyClass object.
end
```


### Using the Built-in Queue Classes

The thread library **thread.rb** has a couple of queueing classes that will be useful from time to time. The class
**Queue** is a thread-aware queue that synchronizes access to the ends of the queue; that is, different threads can share
the same queue without interfering with each other. The class **SizedQueue** is essentially the same, except that it allows
a limit to be placed on the number of elements a given queue instance can hold.

**Queue** and **SizedQueue** have much the same set of methods available because **SizedQueue** actually inherits from
**Queue**. The **SizedQueue** class also has the accessor `max`, used to get or set the maximum size of the queue.

Down below is an example of the Producer-Consumer Problem:

```ruby
require 'thread'

buffer = SizedQueue.new(2)

producer = Thread.new do 
  item = 0 
  loop do
    sleep(rand * 0.1)
    puts "Producer makes #{item}"
    buffer.enq item
    item += 1
  end
end

consumer = Thread.new do
  loop do
    sleep((rand * 0.1) + 0.09)
    item = buffer.deq
    puts "Consumer retrieves #{item}"
    puts " waiting = #{buffer.num_waiting}"
  end
end

sleep 10  # Run a 10 secs, then die and kill threads
```

The methods `enq` and `deq` are the recommended way to get items into and out of the queue.\
The method `empty?` will test for an empty queue, and `clear` will remove all items from a queue.\
The method `size/length` will return the actual number of items in the queue.\

The `num_waiting` method is the number of threads waiting to access the queue. In a plain-old **Queue** 
instance, this is the number of threads waiting to remove elements; with a **SizedQueue**, `num_waiting`
also includes the threads waiting to add elements to the queue.

An optional parameter, `non_block`, defaults to `false` for the `deq` method in the **Queue** class. If 
it is true, an empty queue will give a **ThreadError** rather than block the thread.


### Using Condition Variables

A condition variable is really just a queue of threads. It is used in conjunction with a mutex to provide a higher 
level of control when synchronizing threads. A condition variable allows you to relinquish control of the mutex until a
certain condition has been met. Imagine a situation in which a thread has a mutex locked but cannot continue because the
circumstances aren't right. It can sleep on the condition variable and wait to be awakened when the condition is met.

> It is important to understand that while a thread is waiting on a condition variable, the mutex is released so that other
> threads can gain access. It is also important to realize that when another thread does a signal operation (to awaken the
> waiting thread), the waiting thread acquires the lock on the mutext.

```ruby
require 'thread'

@music  = Mutex.new
@violin = ConditionVariable.new
@bow    = ConditionVariable.new

@violins_free = 2 
@bows_free    = 1

def musician(n)
  3.times do
    sleep rand 
    @music.synchronize do
      @violin.wait(@music) while @violins_free = 0
      @violins_free -= 1
      puts "#{n} has a viloin"
      puts "violins #@violins_free, bows #@bows_free"
      
      @bow.wait(@music) while @bows_free = 0
      @bows_free -= 1
      puts "#{n} has a bow"
      puts "violins #@violins_free, bows #@bows_free"
    end
    
    sleep rand
    puts "#{n}: (...playing...)"
    sleep rand
    puts "#{n}: Now I've finished."
    
    @music.synchronize do 
      @violins_free += 1
      @violin.signal if @violins_free == 1
      @bows_free += 1
      @bow.signal if @bows_free == 1
    end
  end
end

threads = []
3.times { |i| threads << Thread.new { musician(i) } }

threads.each { |t| t.join }
```


### Other Synchronization Techniques

Yet another synchronization mechanism is the monitor, implemented in Ruby in the form **monitor.rb**. This technique is somewhat
more advanced than the mutex; notable you can nest monitor locks.

Like the Spanish Inquisition, nested locks are mostly unexpected. No one, for example, would ever write the following:

```ruby
@mutex = Mutex.new

@mutex.synchronize do
  @mutex.synchronize do
    # ...
  end
end
```

But that doesn't mean that a nested lock can't happen. What if the call to `synchronized` lives in a recursive method? Or suppose one method grabs the
mutex and then innocently calls another method. The answer is – at least when you are using a mutex – is deadlock followed by an ugly exception. 
Because monitors do allow nested locks, this code will run happily:

```ruby
def some_method
  @monitor = Mutex.new

  @monitor.synchronize do
    # ... 
    some_other_method
  end
end

def some_other_method
  @monitor.synchronize do  # No problem with monitor. If a mutex would've been used, a DeadLock would've occurred. 
    # ...
  end
end
```

Like the mutex, Ruby's monitors come in two flavors: the class version, **Monitor**, and the very pedantically named **MonitorMixin**
module. 

The **monitor.rb** file also improves the ConditionalVariable class that comes with the standard thread. The **monitor.rb** version
adds the `wait_until` and `wait_while` methods, which will block a thread based on a condition. It also allows a timeout while waiting
because the wait method has a timeout parameter, which is a number of seconds (defaulting to **nil**).

The **sync.rb** library is one more way of performing thread synchronization (using a two-phase lock with a counter). It defines a 
**Sync_m** module used in an include or an extend (much like **Mutex_m**). This module makes available methods such as `sync_locked?`, 
`sync_shared?`, `sync_exclusive?`, `sync_lock`, `sync_unlock` and `sync_try_lock`.


### Setting a Timeout for an Operation

The **timeout** library is a thread-based solution to timeout-related issues. The `timeout` method executes
a block associated with the method call; when the specified number of seconds has elapsed, it throws a **Timeout::Error**,
which can be caught with a `rescue` clause.

```ruby
require 'timeout'

flag = false
answer = nil

begin
  Timeout.timeout(5) do
    puts "I want a cookie"
    answer = gets.chomp
    flag = true
  end
rescue TimeoutError
  flag = false
end

if flag
  if answer == 'cookie'
    puts "Thank you! Chomp, chomp, ..."
  else
    puts "That's not a cookie!"
    exit
  end
else
  puts "Hey, too slow!"
  exit
end

puts "Bye now.."
```

> Timeouts in Ruby come with two important caveats, however. First, they are not thread-safe. The underlying mechanism of timeouts
> is to create a new thread, monitor the thread for completion, and forcibly kill the thread if it has not completed within the
> timeout specified. As mentioned, killing threads may not be thread-safe operation, because it can leave your program in an unrecoverable
> state.

To create a timeout-like effect safely, write the processing thread such that it will periodically check if it needs to abort. This
allows the thread to do any required cleanup while terminating in a controlled way.

```ruby
require 'prime'

primes = []
generator = Prime.each
start = Time.now

while Time.now < (start + 5)
  10.times { primes << generator.next }
end

puts "Ran for #{Time.now - start} seconds"
puts "Found #{primes.size} primes, ending in #{primes.last}"
```

Although the results from this code may vary, this example demonstrates how to monitor for a timeout without
having to forcibly kill an executing thread.

> Keep in mind that the **Timeout::Error** exception will not be caught by a simple `rescue` with no arguments.
> Calling `rescue` with no arguments will automatically rescue any instance of **StandardError** and its subclasses,
> but **Timeout::Error** is not a subclass of **StandardError**


### Waiting for an Event

In the following example, we see three threads doing the "work" of an application. Another thread simply
wakes up every second, checks the global variable `$flag`, and wakes up two other threads when it sees the flag set.
This saves the three worker threads from interacting directly with the two other threads and possibly making multiple
attempts to awaken them:

```ruby
$flag = true
work1 = Thread.new { job1() }
work2 = Thread.new { job2() }
work3 = Thread.new { job3() }

thread4 = Thread.new { Thread.stop; job4() }
thread5 = Thread.new { Thread.stop; job5() }

watcher = Thread.new do
  loop do
    sleep 1
    
    if $flag
      thread4.wakeup
      thread5.wakeup
      
      Thread.exit
    end
  end
end
```

If at any point during the execution of the job methods the variable `$flag` becomes `true`, `thread4` and `thread5` are guaranteed
to start within a second. After that, the watcher thread terminates.


### Collection Searching in Parallel

Threads also make it straightforward to work on a number of alternative solutions simultaneously.

```ruby
require 'thread'

def threaded_max(interval, collections)
  threads = []
  
  collections.each do |col|
    thread << Thread.new do
      me = Thread.current
      me[:result] = col.first
      col.each do |n|
        me[:result] = n if n > me[:result]
      end
    end
  end
  
  sleep(interval)
  
  threads.each { |t| t.kill }
  results = threads.map { |t| t[:result] }
  results.compact.max   # Max be nil
end


collections = [
  [ 1, 25, 3, 7, 42, 64, 55 ],
  [ 3, 77, 1, 2, 3, 5, 7, 9, 11, 13, 102, 67, 2, 1],
  [ 3, 33, 7, 44, 77, 92, 10, 11]]

biggest = threaded_max(0.5, collections)
```

In the example above, the threads report their results back in a thread local value called `:result`. The threads
update `:result` every step of the way because te main bit of the `threaded_max` method will only wait so long before it
kills off all the threads and returns the biggest value found so far. Finally, `threaded_max` can conceivably actually return
`nil`: No matter how long we wait, it is possible that the threads will not have done anything before `threaded_max` runs out
of patience.

Does a bunch of threads actually make things faster? It's hard to say. The answer probably depends on your operating system as 
well as on the number of arrays you are searching.


## Fibers and Cooperative Multitasking

Along with full operating system threads, Ruby also provides _fibers_, which can be described as cut-down threads or as code 
blocks with superpowers.

Fibers do not create an OS thread, but they can contain a block that maintains its state, can be paused or resumed, and can
yield results. To see what this means, let's start by creating one with a call to `Fiber.new`:

```ruby
fiber = Fiber.new do
  x = 2
  Fiber.yield x
  x = x * 2
  Fiber.yield x
  x * 2
end
```

`Fiber.new` doesn't actually cause any of the code in the fiber's block to execute. To get things going, you need to call
the `resume` method. Calling `resume` will cause the code inside the block to run until it either hits the end of the block
or `Fiber.yield` is called. Because our fiber has a `Fiber.yield` on the second line of the block, the initial call to `resume`
will run until that second line. The call to `resume` returns whatever is passed to `Fiber.yield` so that our call to `resume` 
will return `2`.

```ruby
answer1 = fiber.resume    # answer1 will be 2
```

So far this is all very lambda-like, but now things get interesting. If we call `resume` a second or third time, the fiber
will pick up where it left off:

```ruby
answer2 = fiber.resume  # should be 4
answer2 = fiber.resume  # should be 8
```

Given all this, you can look at a fiber as a restartable code block. You can keep restarting a fiber until it finishes
running the code block; call `resume` after that and you will raise a **FiberError**.

Fibers run in the thread that calls `resume`, hanging onto it only until the fiber finishes or hits the next `Fiber.yield`. In
other words, whereas threads implement preemptive multitasking, fibers implement cooperative multitasking.

Along with the basic `Fiber.new` and `yield`, you can get some bonus fiber methods if you require the **fiber** library. Doing
so will give you access to `Fiber.current`, which returns the currently executing fiber instance. You also get the `alive?`
instance method, which will tell you if a fiber is still alive. Finally, the **fiber** library will give every fiber instance
the `transfer` instance method, which allows fibers to transfer control from ont to the other (making them truly cooperative).

The power that fibers provide, of pausing execution until a later time, is most useful when it is useful to wait before 
calculating the next item in a succession. As you may have noticed, this is very similar to how Ruby's **Enumerator** objects
work. Perhaps unsurprisingly, every enumerator is in fact implemented using fibers. The `next`, `take`, and every other enumerator
method simply calls `resume` on its fiber as many times as is needed to produce the requested results.
