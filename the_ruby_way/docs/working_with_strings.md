# Working with Strings

1. [Representing Strings with Alternate Notations](#representing-strings-with-alternate-notations)
2. [Using Here-Documents](#using-here-documents)
3. [Tokenizing a String](#tokenizing-a-string)
4. [Formatting a String](#formatting-a-string)
5. [Controlling Uppercase and Lowercase](#controlling-uppercase-and-lowercase)
6. [Accessing and Assigning Substrings](#accessing-and-assigning-substrings)
7. [Substituting in Strings](#substituting-in-strings)
8. [Searching a String](#searching-a-string)
9. [Delayed Interpolation of Strings](#delayed-interpolation-of-strings)
10. [Converting String to Numbers (Decimal and Otherwise)](#converting-string-to-numbers-decimal-and-otherwise)
11. [Compressing Strings](#compressing-strings)
12. [Counting Characters in Strings](#counting-characters-in-strings)
13. [Reversing a String](#reversing-a-string)
14. [Removing Duplicate Characters](#removing-duplicate-characters)
15. [Removing Specific Characters](#removing-specific-characters)
16. [Printing special Characters](#printing-special-characters)
17. [Generating Successive Strings](#generating-successive-strings)

## Representing Strings with Alternate Notations

Sometimes we want to represent strings that are rich in metacharacters, such as single quotes, double quotes, and more.
For these situations, we have the `%q` and `%Q` notations. Following either of these is a string within a pair of delimiters;
Preferred are the square brackets.

The difference between the `%q` and `%Q` variants is that the former acts like a single-quoted string, and the latter 
like a double-quoted string.

```ruby
s1 = %q[This is not a tab: (\t)]   # same as 'This is not a tab: \t'
s2 = %q[This IS a tab: (\t)]       # same as "This IS a tab: \t"
```


## Using Here-Documents

If you want to represent a long string spanning multiple lines, you can certainly use a regular quoted string. However,
the indentation will be part of the string.

Another way is to use a _here-document_, a string that is inherently multiline. The syntax is the `<<` symbol, followed
by and end marker, then zero or more lines of text, and finally the same end marker on a line by itself:

```ruby
str = <<EOF
Once upon a midnight, dreary,
While I pondered weak and weary...
EOF
```

They may be "stacked" as well.

```ruby
some_method(<<STR1, <<STR2, <<STR3)
first piece 
of text...
STR1
second piece...
STR2
third piece
of text.
STR3
```

By default, a here-document is like a double-quoted string. But if the end marker is single-quoted, the here document
behaves like a single-quoted string.

If a here document's end marker is preceded by a hyphen, the end marker may be indented. Only the spaces before the 
end marker are deleted from the string, not those on the previous lines:

```ruby
str = <<-EOF
  Each of these lines
  starts with a pair
  of blank spaces.
EOF
```


## Tokenizing a String

The `split` method parses a string and returns an array of tokenized strings. It accepts two params: a delimiter and a 
field limit (which is an integer).

The delimiter defaults to whitespace. Actually, it uses `$`; or the english equivalent `$FIELD_SEPARATOR`. 

The `limit` parameter places an upper limit on the number of fields returned, according to these rules:
- If it is omitted, trailing null entries are suppressed.
- If it is a positive number, the number of entries will be limited to that number (stuffing the rest of the string into
  the last field as needed). Trailing null entries are retained.
- If it is a negative number, there is no limit to the number of fields, and trailing null entries are retained.

```ruby

str = "alpha,beta,gamma,," 
list1 = str.split(",")    # ["alpha","beta","gamma"]
list2 = str.split(",",2)  # ["alpha", "beta,gamma,,"]
list3 = str.split(",",4)  # ["alpha", "beta", "gamma", ","]
list4 = str.split(",",8)  # ["alpha", "beta", "gamma", "", ""]
list5 = str.split(",",-1) # ["alpha", "beta", "gamma", "", ""]
```

Similarly, the `scan` method can be used to match regex or strings against a target string.

```ruby
str = "I am a leaf on the wind"

arr = str.scan("a") # ["a", "a", "a"]
```


## Formatting a String

This is done with the `sprintf`. It takes a string and a list of expressions as parameters and returns a string. 

```ruby
name = "Bob"
age = 28
str = sprintf("Hi, %s... I see you're %d years old.", name, age)
```

Why use this instead of simply interpolating values into a string using the `#{expr}` notation? The answer is that
`sprintf` makes it possible to do extra formatting, such as specifying a max width, max number of decimal places,
adding a suppressing lead zeroes, left-justifying, right-justifying, and more.

The **String** class has the method `%`, which does much the same thing. It takes a single value or an array of
values of any type:

```ruby
str = "%-20s  %3d" % [name, age]
```


## Controlling Uppercase and Lowercase

The `downcase` and `upcase` are used to convert a string to lowercase or uppercase.

The `capitalize` method capitalizes the first char of a string while forcing all the remaining chars to lowercase.

The `swapcase` method exchanges the case of each letter in a string.

There is also the `casecmp` method, which acts like the `<=>` method but ignores case:

```ruby
n1 = "abc".casecmp("xyz") # -1
n2 = "abc".casecmp("XYZ") # -1
n4 = "ABC".casecmp("abc") # 0
n5 = "xyz".casecmp("abc") # 1
```

Each of these has an in-place equivalent.


## Accessing and Assigning Substrings

In Ruby, substrings may be accessed in several different ways. Normally the bracket notation is used, as for an array,
but the brackets may contain a pair of Fixnums, a range, a regex, or a string.

If a pair of **Fixnum** values is specified, they are treated as an offset and a length.

A range may be specified. In this case, the range is taken as a range of indecies into the string. Ranges may have
negative numbers, but numerically lower number must still be first in the range. If the range is "backward" of the initial
value is outside the string, `nil` is returned.

```ruby
str = "Winston Churchill"
sub1 = str[8..13] # "Church" 
sub2 = str[-4..-1] # "hill" 
sub3 = str[-1..-4] # nil 
sub4 = str[25..30] # nil
```

If a regular expression is specified, the string matching the pattern will be returned. If there is no match, `nil` will
be returned.

```ruby
str = "Alistair Cooke"
sub1 = str[/l..t/]  # "list" 
sub2 = str[/s.*r/]  # "stair" 
sub3 = str[/foo/]   # nil
```

If a string is specified, it will be returned if it appears as a substring (or `nil` if it doesn't).

> It is important to realize that the notations described here will serve for assigning values as well as for accessing them.


## Substituting in Strings

The `sub` and `gsub` methods provide more advanced pattern-based capabilities. There are also `sub!` and `gsub!`, their
in-place counterparts.

The `sub` method substitutes the first occurrence of a pattern with the given substitute string or the given block.

```ruby
s1 = "spam, spam, and eggs" 
s2 = s1.sub(/spam/,"bacon")             
# "bacon, spam, and eggs"

s3 = s2.sub(/(\w+), (\w+),/,'\2, \1,')  
# "spam, bacon, and eggs"

s4 = "Don't forget the spam."
s5 = s4.sub(/spam/) { |m| m.reverse }   
# "Don't forget the maps."

s4.sub!(/spam/) { |m| m.reverse }
# s4 is now "Don't forget the maps."
```

The `gsub` (global substitution) is essentially the same except that all matches are substituted rather than just the first.


## Searching a String

The `index` method returns the starting location of the specified substring, char, or regex. If the item is not found, the
result is `nil`.

The method `rindex` (right index) starts from the right side of the string. The numbering, however, proceeds from the 
beginning, as usual.

The `include?` method simply tells whether the specified substring or character occurs within the string.


## Appending an Item onto a String

The append operator (`<<`) can be used to append a string onto another string. It is "stackable" in that multiple operations
can be performed in sequence on a given receiver.


## Delayed Interpolation of Strings

Sometimes we might want to delay the interpolation of values into a string. There's no perfect way to do this.

```ruby
str = Proc.new do |name, nation|
  "#{name} is my name, and #{nation} is my nation"
end

s2 = str.call("Gulliver Foyle", "Terra")
```


## Converting String to Numbers (Decimal and Otherwise)

The simple case is trivial, and these are equivalent:

```ruby
x = "123".to_i      # 123
y = Integer("123")  # 123
```

When a string is not a valid number, though, their behavior differ:

```ruby
x = "123junk".to_i       # silently returns 0
y = Integer("123junk")   # error
```

> `to_i` stops converting when it reaches a non-numeric character, but **Integer** raises an error.


## Compressing Strings

The **Zlib** library provides a way of compressing and decompressing strings and files.

The **Deflate** and **Inflate** classes have class methods named `deflate` and `inflate`, respectively. The `deflate`
method (which obviously compresses) has an extra parameter to specify the style of compression. The styles show a typical
trade-off between compression quality and speed; `BEST_COMPRESSION` results in a smaller compressed string, but compression
is relatively slow; `BEST_SPEED` compresses faster but doesn't compress as much. The default (`DEFAULT_COMPRESSION`) is 
typically somewhere in between in both size and speed.

```ruby
require 'zlib'
include Zlib

long_string = ("abcde"*71 + "defghi"*79 + "ghijkl"*113)*371
# long_string has 559097 chars

s1 = Zlib.deflate(long_string, BEST_SPEED)        # 4188 chars
s2 = Zlib.deflate(long_string)                    # 3569 chars
s3 = Zlib.deflate(long_string, BEST_COMPRESSION)  # 2120 chars
```


## Counting Characters in Strings

The `count` method counts the number of occurrences of any of a set of specified characters.

```ruby
s1 = "abracadabra"
a = s1.count("c")     # 1
b = s1.count("bdr")   # 5
```

The string parameter is like a simple regex. If it starts with a caret (^), the list is negated. A hyphen (-) indicates a range of characters.


## Reversing a String

A string may be reversed simply by using the `reverse` method (or its in-place counterpart `reverse!`):

```ruby
s1 = "Star Trek"
s2 = s1.reverse   # kerT ratS
s1.reverse        # s1 is now "kerT ratS"
```


## Removing Duplicate Characters

Runs of duplicate characters may be removed using the `squeeze` method. If a parameter is specified, only those characters will be squeezed.
The method understands the hyphen and the caret.

```ruby
s1 = "bookkeeper"
s2 = s1.squeeze       # "bokeper"
s3 = "Hello..."
s4 = s3.squeeze       # "Helo."
```


## Removing Specific Characters

The `delete` method removes characters from a string if they appear in the list of characters passed as a parameter:
The method understands the hyphen and the caret.

```ruby
s1 = "To be, or not to be"
s2 = s1.delete("b")         # "To e, or not to e"
```


## Printing special Characters

The `dump` method provides explicit printable representations of characters that may ordinarily be invisible or print 
differently.

```ruby
s1 = "Listen" << "\007\007\007"   # Add three ASCII BEL chars
puts s1.dump                      # Prints Listen\007\007\007
```


## Generating Successive Strings

On rare occasions, we may want to find the "successor" value for a string; for example, the successor for "aaa" is "aab"
(then "aad" ,"aae", and so on).

```ruby
droid = "R2D2"
improved = droid.succ   # R2D3
pill = "Vitamin B"
pill2 = pill.succ       # Vitamin C
```

> It is not recommended to use this feature unless the values are predictable and reasonable. If you start with a string
> that is esoteric enough, you will eventually get strange and surprising results.

There is also an `upto` method that applies `succ` repeatedly in a loop until the desired final value is reached.

```ruby
"Files, A".upto "Files, X" do |letter|
  puts "Opening: #{letter}"
end
```

