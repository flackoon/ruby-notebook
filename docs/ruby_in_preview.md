# Ruby in Preview

1. [Basic Ruby Syntax and Semantics](#basic-ruby-syntax-and-semantics)\
   1.1. [Keywords and Identifiers](#keywords-and-identifiers)\
   1.2. [Comments and Embedded Documentation](#comments-and-embedded-documentation)\
   1.3. [Constants, Variables, and Types](#constants-variables-and-types)\
   1.4. [Looping and Branching](#looping-and-branching)\
   1.5. [Exceptions](#exceptions)\
2. [OOP in Ruby](#oop-in-ruby)\
   2.1. [Objects](#objects)\
   ...

## Basic Ruby Syntax and Semantics

Ruby is an _agile_ language. It is "malleable" and encourages frequent, easy(manual) refactoring.

Ruby is an _interpreted_ language. Of course, there may be later implementations of a Ruby compiler for performance
reasons, but we maintain that an interpreter yields great benefits not only in rapid prototyping but also in the shortening
of the development cycle overall.

Ruby is an _expression-oriented_ language. Why use a statement when an expression will do? This means, for instance, 
that code becomes more compact as the common parts are factored out and repetition is removed.

Ruby is a very _high-level_ language. One principle behind the language design is that the computer should work for the 
programmer rather than vice versa.

To begin with, Ruby is essentially a line-oriented language. Tokens can be crowded onto a single line as long as they are
separated by whitespace as needed. Statements may share a single line if they are separated by semicolons; this is the 
only time the terminating semicolon is really needed. A line may be continued to the next line by ending it with a 
backlash or by letting the parser know that the statement is not complete.

There's no main program as such; execution proceeds in general from top to bottom.


### Keywords and Identifiers

The keywords in Ruby typically cannot be used for other purposes.
These are as follows:

|BEGIN|END|alias|and|begin|
|---|---|---|---|---|
|break|case|class|def|defined?|
|do|else|elsif|end|ensure|
|false|for|if|in|module|
|next|nil|not|or|redo|
|rescue|retry|return|self|super|
|then|true|undef|unless|until|
|when|while|yield|

Variables and other identifiers normally start with an alphabetic letter or a special modifier. The basic rules are as follows:

- Local Variables (and pseudovariables such as self and nil) begin with a lowercase letter on an underscore.
- Global variables begin with $.
- Instance variables begin with @.
- Class variables begin with @@.
- Constants begin with capital letters.
- For purposes of forming identifiers, the underscore (_) may be used as a lowercase letter.
- Special variables starting with a dollar sign (such as `$1` and `$/`) are set by the Ruby interpreter itself.


### Comments and Embedded Documentation

Comments in Ruby begin with a pound sign (#) outside a string or character constant and proceed to the end of the line.

Given two lines starting with `=begin` and `=end`, everything between those lines (inclusive) is treated as a comment.
(These can't be preceded by whitespace.)

```ruby
=begin
Everything on lines
inside here will be a
comment as well.
=end
```


### Constants, Variables, and Types

In Ruby, variables do not have types, but the objects they refer to do have types. The simple data types are character,
numeric, and string.

> Generally, a double-quoted string is subject to additional interpretation, and a single-quoted string is more "as is", 
> allowing only an escaped backlash.

In double-quoted strings, we can do "interpolation" of variables and expressions.

There is a special kind of string worth mentioning, primarily useful in small scripts used to glue together larger programs.
The command output string is sent to the operating system as a command to be executed, whereupon the output of the command is 
substituted back into the string. The simple form of this string uses the _grave accent_ as a beginning and ending delimeter;
the more complex form uses the `%x` notation.

```ruby
‘whoami’
‘ls -l’
%x[grep -i meta *.html | wc -l]
```

Because the array of strings is so common (and so inconvenient ot type), a special syntax has been set aside for it, similar to what
we have seen already:

```ruby
%w[alpha beta gamma delta]
```

A hash constant is typically represented between delimiting braces, with the symbol `=>` separating the individual keys and values.
The key can be thought of as an index where the corresponding value is stored. There is no restriction on types of the keys or the
corresponding values.

```ruby
{1 => 2, "cat": "cats", [4,5,6] => "my array"}
```


### Operations and Precedence

Ruby's operators are arranged here in order from highest to lowest precedence:

|::|Scope|
|---|---|
|[]|Indexing|
|**|Exponentiation|
|+ - ! ~|Unary positive/negative, not, ...|
|* / %|Multiplication, division, ...|
|+ -|Addition/substraction|
|<< >>|Logical shifts, ...|
|&|Bitwise AND|
| &#124;  ^|Bitwise OR, XOR|
|> >= < <=|Comparison|
|== === <=> != =~ !~|Equality, inequality, ...|
|&&|Boolean AND|
|&#124;&#124;|Boolean OR|
|.. ...|Range operators|
|= (also +=, -=, ...)|Assignment|
|?:|Ternary decision|
|not|Boolean negation|
|and or|Boolean AND, OR|

Some of the preceding symbols serve mor than one purpose.


### Looping and Branching

The `case` statement in Ruby is more powerful than in most languages. This multiway branch can even test for conditions other
than equality – for example, a matched pattern(regex). The test used by the `case` statement is called the case _equality operator_ (`===`),
and its behavior varies from one object to another.

As for looping mechanisms, Ruby has a rich set. The `while` and `until` control structures are both pretest loops, and both work as expected: 
One specifies a continuation condition for the loop, and the other specifies a termination condition. They also occur in “modifier” form, 
such as `if` and `unless`. There is also the `loop` method of the **Kernel** module (by default an infinite loop), and there are iterators
associated with various classes.

We need ways to control loops. The first way is the `break` keyword. It is used to "break out" of a loop; in the case of nested loops, only
the innermost one is halted.

The `redo` keyword jumps to the start of the loop body in `while` and `until` loops.

The `next` keyword effectively jumps to the end of the innermost loop and resumes execution from that point. It works for any loop or
iterator.


### Exceptions

Ruby supports _exceptions_, which are standard means of handling unexpected errors in modern programming languages.

The `raise` statement raises an exception. Note that `raise` is not a reserved word but a method of the module **Kernel**. (There is an alias
named `fail`.)

The `begin-end` block is used for handling exceptions in Ruby.

The block, however, may have one or more `rescue` clauses in it. If an error occurs at any point in the code, between `begin` and `rescue`, 
control will be passed immediately to the appropriate `rescue` clause:

```ruby
begin
   # ...
rescue ArgumentError 
   # ...
rescue ZeroDivisionError
   # ...
rescue => err
   puts err
end
```

When no error type is specified, the `rescue` clause will catch any descendant of **StandardError**.

In the event that error types are specified, it may be that an exception does not match any of these types. For that situation, 
we are allowed to use an `else` clause after all the `rescue` clauses:
```ruby
begin
  # Error-prone code...
rescue Type1 
   #...
rescue Type2 
   #...
else
  # Other exceptions...
end
```

In many cases, we want to do some kind of recovery. In that event, the keyword `retry` (within the body of a `rescue` clause) restarts
the `begin` block and tries those operations again.

```ruby
begin
   # Error-prone code
rescue
   # Attempt recovery
   retry
end
```

Finally, it is sometimes necessary to write clean-up code after a `begin-end` block. In the event this is necessary, an `ensure`
clause can be specified:

```ruby
begin
   # Error-prone code
rescue
   # Handle exceptions
ensure
   # This code is always executed
end
```

Exceptions may be caught in two other ways. First, there is a modifier form of the rescue clause:

```ruby
x = a / b rescue puts("Division by zero!")
```

In addition, the body of a method definition is an implicit `begin-end` block; the `begin` is omitted, and the
entire body of the method is subject to exception handling, ending with the `end` of the method:

```ruby
def some_method
   # ..
rescue
   # Recovery
end
```

## OOP in Ruby

### Objects

In Ruby, all numbers, strings, arrays, regular expressions, and many other entities are actually objects. Work is dony by executing the methods
belonging to the object.

In Ruby, every object is an instance of some class; the class contains the implementation of the methods.

In addition to encapsulating its own attributes and operations, an object in Ruby has an identity.
