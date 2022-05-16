# Designing Useful Custom Classes

## Learning when to create a custom class

Choosing to create a custom class is always a trade-off. There is always a cost in creating a custom class versus using
a core class – it results in some amount off conceptual overhead. 

There are two main benefits of creating a custom class. One is that it encapsulates state, so that the state of the
object can only be manipulated in ways that make sense for the object. The second benefit is that classes provide a
simple way for calling their methods.

As a simple example, consider a stack of objects. With core classes, you ca implement it using a standard **Array**
class. This approach is intuitive and maintainable, however, if external code can get a reference to the object, it can
violate the stack design and add to the bottom of it.

This can be, of course, avoided by encapsulating the login into a custom class. If you are sharing this stack object so
that users operate on stacks directly and pass the stacks to other objects, this encapsulation makes sense. However, if
your stack is just an implementation detail used in another class that has its own encapsulation, then a custom class
for it is probably unnecessary complexity.

In addition to being less intuitive, it results in slower runtime performance due to additional indirection and slower
garbage collection + greater memory use.

Another case where having a custom class makes sense is when you need both information hiding and custom behavior (input
data validation).

One final thing to consider before creating a custom class – how many places you will be using it.


## Handling trade-offs in SOLID design

Using these principles can result in well-structured classes. However, the principles should not be applied dogmatically.


### The single-responsibility principle

The basic idea of the single-responsibility principle is that a class should basically serve one purpose. On the face of
it, this is a good general rule. However, this principle is not generally used for justifying designing a class to serve
a single purpose. It's almost always used to justify splitting a single class that serves multiple purposes into multiple
classes that each serve a single purpose, or at least a smaller number of purposes. This application of the principle can
often result in an increased complexity, especially in a small scope.

> Take Ruby's **String** class as an example. It can serve multiple purposes. It can represent text and it can also
> represent binary data. It can handle many different purposes, and the great thing about it is that you don't need to
> conceptually deal with **Text, Data, TextBuilder, DataBuilder, TextModifier,** and **DataModifier** classes.

A good question to ask yourself when deciding whether to use the principle to split up a class is – "Would I be able to
use any of the newly split classes in additional places in my application or library?". 
Another good question to ask yourself is – "Do I want to be able to easily replace certain parts of this class with
alternative parts?"

Consider the following example:
You have a program that prints reports. In the beginning it has the ability to convert a single type of report to a
single format. One design approach is to have a single **Report** class that holds all of the data and the methods used
for formatting the report.

Alternatively, as your program grows, you might need to have different formatters for the reports. In this case, its
good to split your class into two new ones – **ReportContent** and **ReportFormatter**. You may then have different
types of reports and using separate classes allows you to easily replace only part of the class:

```ruby
report_content = ReportContent.new data
report_formatter = ReportFormatter.new
puts report_formatter.format(report_content)

# or
report_formatter = ReportFormatter.for_type(report_type).new
puts report_formatter.format(report_content)
```

If you know in advance you'll need multiple report formats, then separation is probably a good idea. However, if you
start out with a single report format, single class is a better approach.

> You may never need to deal with multiple report formats, and burdening your code with excess complexity will make it
> harder to use. As a general principle, you should delay increasing complexity in your class designs until you actually
> need it.


### The open-closed principle

The open-closed principle stipulates that a class should be open for extension, but closed for modification. In Ruby,
pretty much all classes are open for both extension and modification. Ruby itself completely ignores the open-closed
principle, and actively works to make sure classes aren't closed for modification.

TL;DR;

It is pointless to try to get Ruby classes to be open for extension and closed for modification. You choices are either
frozen and closed for both modification and extension, or unfrozen and open for both modification and extension.


### The Liskov substitution principles

The Liskov substitution principle states that any place in the code where you can use an object of type **T**, you can
also use an object of a subtype of **T**. In terms of Ruby, this means that any place in your code where you are using
an instance of a class, you can also use an instance of a subclass without anything breaking.

In general, this is a good principle to follow. When you subclass an existing class, if you override a method of the
class, you should attempt to ensure that it accepts the same argument types and returns the same argument type. While
useful to follow in general, you should not be dogmatic about applying it.


### The interface segregation principle

The interface segregation principle states that clients should not be forced to depend on methods they do not use. While
this doesn't strictly apply to Ruby directly, since Ruby will only call methods that are used, a looser interpretation
is that this applies classes to how large should be in terms of methods.

Classes with a large number of methods, where the programmer is using only a few of the methods, can be more difficult
to understand. If 80% of your users are the same 20% of methods of a class, it may make sense to move many of the methods
to a separate module (assuming backwards compatibility is not an issue).

In the real world, it's less likely that you'll have 80% of users using the same 20% of the methods. More likely, you'll
have 80% of users using 20% of the methods, but which 20% are used varies widely from one user to the next. In that case
there is no easy way to separate the code.


### The dependency inversion principle

The dependency inversion principle states that high-level modules should not depend on low-level modules, and both
high-level modules and low-level modules should depend on abstractions. It also states that abstractions should not
depend on concrete implementations, but that concrete implementations should depend on abstractions.

One concrete implementation of the dependency inversion principle is dependency injection. Ruby doesn't require that as
much as other programming languages due to its flexibility of allowing singleton methods on almost all objects. It can
still be used in Ruby though.


## Deciding on larger classes or more classes

||Larger classes|More classes|
|---|---|---|
|Conceptually simpler code|Yes|No|
|More modular code (easier to change parts)|No|Yes|

There must be a balance.


Example:
Let's say we are building a lib to handle the construction of [HTML tables](../snippets/html_table.rb).

The single-class approach contains all the logic in a single method, and will probably perform the best. It looks a
little ugly though, with the manual concatenation of strings. Perhaps it could be fixed by using separate classes per
element type?

The second approach uses six classes: the **HTMLTable** class, an **Element** base class, and **Table, Tbody, Tr**, and
**Td** classes, which are created via metaprogramming. Each of these classes does a single thing, so arguably this does
a better job adhering to the single-responsibility principle. However, each of the **Element** subclasses is doing
essentially the same thing, and you could avoid the use of separate subclasses by passing the type in as a parameter to
a method of the **Element** class.

Definitely, the best part of this design is that all HTML generation happens in a single place.
In addition to being overly complex, probably the worst part of this design is that it's probably slow, not just for the
additional object creation, but also due to all of the temp strings. If one of the data cells is large, the memory used
will be at least 8 times larger than the size of the large data cell, since the following strings will contain the
large data:

- The string containing the large data
- The string created by CGI.escapeHTML
- The string created in HTMLTable::Td#to_s
- The string created in HTMLTable#to_s when joining the array of Td instances
- The string created in HTMLTable::Tr#to_s
- The string created in HTMLTable#to_s when joining the array of Tr instances
- The string created in HTMLTable::Tbody#to_s
- The string created in HTMLTable::Table#to_s

You can add a `wrap` method that takes the HTML string being build and the element ype and uses an append-only design
for building the HTML, yielding between the opening tags and the closing tags.

This approach is slightly more complex than the initial approach, but it performs almost as well and will make it easier
to expand later.


## Learning when to use custom data structures

Ruby only offers 2 main core data structures for collections, arrays, and hashes. They are not very simple though.
Actually, they are complex internally. For example, when adding an element on an array when the array doesn't have any
room internally, Ruby expands the array not by a single element, but in relation to how large the array currently is, so
if you keep adding elements to the array, it doesn't need ot resize the array each time.

Likewise, for small hash tables, Ruby may store the hash table as a simple list if it thinks it will be faster to scan
the list than use a real hash table. If it grows, Ruby will internally convert the list into a real hash table, at the
point at which it roughly determines that it will be faster to use a separate hash lookup.
