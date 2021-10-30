# I/O and Data Storage

## Opening and Closing files

The class method `File.new` instantiates a **File** object and opens the file. The first
parameter is naturally the **filename**.

The _optional_ second parameter is called the **mode** string and tells how to open the file,
whether for reading, writing, and so on. This **defaults** to "r" for reading.

```ruby
file1 = File.new("one")       # Open for reading
file2 = File.new("two", "w")  # Open for writing
```

Another form for `new` takes 3 parameters. In this case, the second parameter specifies the 
original permissions for the file, and the third is a set of flags ORed together. The flags are
constants such as `File::CREAT` (create the file when it is opened if it doesn't already exist) 
and `File::RDONLY` (open for reading only). This form is rarely used.

```ruby
file = File.new("three", 0755, File::CREAT|File::WRONLY)
```

> As a courtesy to the operating system and the runtime development, always close a file that 
> you open. In the case of a file open of writing, this is more than mere politeness and can 
> actually prevent lost data. 
> 
> ```ruby
> out = File.new("captains.log", "w")
> # Process file
> out.close
> ```

There is also an `open` method. In its simplest form it's merely a synonym for `new`.
It can also take a block. When one is specified, the open file is passed in as a parameter to the
block. The file remains open throughout the scope of the block and is closed automatically at the 
end.

```ruby
File.open("somefile", "w") do |file| 
  file.puts "Line 1"
  file.puts "Line 2"
  file.puts "Third and final line"
end
```

## Updating a file

Suppose that we want to open a file for reading and writing. This is done simply by adding 
a plus sign (+) in the file mode when we open the file.

```ruby
f1 = File.new("file1", "r+")
# Read/write, starting at beginning of file.

f2 = File.new("file2", "w+")
# Read/write; truncate existing file or create a new one.

f3 = File.new("file3", "a+")
# Read/write; start at end of existing file or createa a 
# new one.
```

## Locking files

On OS' where it is supported, the `flock` method will lock or unlock a file. The second
parameter is one of these constants `File::LOCK_EX`, `File::LOCK_NB`, `File::LOCK_SH`, 
`File::LOCK_UN`, or a logical-OR of two or more of these. Note, of course, that many of 
these combinations will be nonsensical.

```ruby
file = File.new("somefile")
file.flock(File::LOCK_EX) # Lock exclusively; no other process may use this file.
file.flock(File::LOCK_UN) # Unlock.

file.flock(File::LOCK_SH) # Lock with a shared lock(other processes may do the same).
file.flock(File::LOCK_UN) # Unlock.

locked = file.flock(File::LOCK_EX | File::LOCK_NB)
# Try to lock the file, but don't block if we can't; in that case, 
# locked will be false.
```