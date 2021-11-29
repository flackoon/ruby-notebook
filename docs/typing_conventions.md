## _Duck typing_

The term duck typing, originated with Dave Thomas. It refers to the old saying that if something 
looks like a duck, walks like a duck, and quacks like a duck, it might as well be a duck. Exactly 
what this term means may be open to discussion; It rather refers to the tendency of Ruby to be less 
concerned with the class of an object and more concerned with what methods can be called on it and 
what operations can be performed on it. Therefore, in Ruby we rarely use **is_a?** or **kind_of?**, 
but we more often use the **respond_to?** method. Most often of all, we simply pass an object to a 
method and expect that an exception will be raised if it is used inappropriately.\ 

That usually happens sooner rather than later, but the exceptions that are raised may be hard to 
understand and debug quickly.

## here-document

This is a string that is **inherently** multiline. The syntax is the `<<` symbol, followed by an
end marker, then zero or more lines of text, and finally the same end marker on a line by itself.

```ruby
str = <<EOF
Once upon a midnight dreary,
While I pondered weak and weary,
EOF
```

By default, a here-document is like a **double-quoted string** – that is, its contents are subject 
to interpretation of escape sequences and interpolation of embedded expressions.\
But if the end marker is single-quoted, the here-document behaves like a single-quoted string:

```ruby
str = <<‘EOF’
This isn’t a tab: \t
and this isn’t a newline: \n
EOF
```

If a here-document’s end marker is preceded by a **hyphen**, the end marker **may be indented**. 
Only the spaces before the end marker are deleted from the string, not those on previous lines:

```ruby
str = <<-EOF
    Each of these lines 
  starts with a pair
    of blank spaces. 
EOF
```