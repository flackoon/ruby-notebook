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
