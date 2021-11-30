# I/O and Data Storage

1. [Working with Files and Directories](#working-with-files-and-directories)\
   1.1. [Opening and Closing files](#opening-and-closing-files)\
   1.2. [Updating a file](#updating-a-file)\
   1.3. [Locking files](#locking-files)\
   1.4. [Performing Buffered and Unbuffered I/O](#performing-buffered-and-unbuffered-io)\
   1.5. [Manipulating File Ownership and Permissions](#manipulating-file-ownership-and-permissions)\
   1.6. [Retrieving and Setting Timestamp information](#retrieving-and-setting-timestamp-information)\
   1.7. [Checking File Existence and Size](#checking-file-existence-and-size)\
   1.8. [Checking Special File Characteristics](#checking-special-file-characteristics)\
   1.9. [Working with Pipes](#working-with-pipes)\
   1.11. [Manipulating Pathnames](#manipulating-pathnames)\
   1.12. [Command-Level File Manipulation](#command-level-file-manipulation)\
   1.13. [Copying a Stream](#copying-a-stream)\
   1.14. [Working with Temporary Files](#working-with-temporary-files)\
   1.15. [Changing and Setting the Current Directory](#)\
   1.16. [Changing the Current Root](#changing-the-current-root)\
   1.17. [Iterating over Directory entries](#iterating-over-directory-entries)\
   1.18. [Getting a list of Directory Entries](#getting-a-list-of-directory-entries)\
   1.19. [Creating a Chain of Directories](#creating-a-chain-of-directories)\
   1.20. [Deleting a Directory Recursively](#deleting-a-directory-recursively)\
   1.21. [Finding files and directories](#finding-files-and-directories)
2. [Higher-Level Data access](#higher-level-data-access)\
   2.1. [Simple Marshaling](#simple-marshaling)

## Working with Files and Directories

### Opening and Closing files

The class method `File.new` instantiates a **File** object and opens the file. The first parameter is naturally the **
filename**.

The _optional_ second parameter is called the **mode** string and tells how to open the file, whether for reading,
writing, and so on. This **defaults** to "r" for reading.

```ruby
file1 = File.new("one") # Open for reading
file2 = File.new("two", "w") # Open for writing
```

Another form for `new` takes 3 parameters. In this case, the second parameter specifies the original permissions for the
file, and the third is a set of flags ORed together. The flags are constants such as `File::CREAT` (create the file when
it is opened if it doesn't already exist)
and `File::RDONLY` (open for reading only). This form is rarely used.

```ruby
file = File.new("three", 0755, File::CREAT | File::WRONLY)
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

There is also an `open` method. In its simplest form it's merely a synonym for `new`. It can also take a block. When one
is specified, the open file is passed in as a parameter to the block. The file remains open throughout the scope of the
block and is closed automatically at the end.

```ruby
File.open("somefile", "w") do |file|
  file.puts "Line 1"
  file.puts "Line 2"
  file.puts "Third and final line"
end
```


### Updating a file

Suppose that we want to open a file for reading and writing. This is done simply by adding a plus sign (+) in the file
mode when we open the file.

```ruby
f1 = File.new("file1", "r+")
# Read/write, starting at beginning of file.

f2 = File.new("file2", "w+")
# Read/write; truncate existing file or create a new one.

f3 = File.new("file3", "a+")
# Read/write; start at end of existing file or createa a 
# new one.
```


### Locking files

On OS' where it is supported, the `flock` method will lock or unlock a file. The second parameter is one of these
constants `File::LOCK_EX`, `File::LOCK_NB`, `File::LOCK_SH`,
`File::LOCK_UN`, or a logical-OR of two or more of these. Note, of course, that many of these combinations will be
nonsensical.

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


### Performing Buffered and Unbuffered I/O

Ruby does its own internal buffering in some cases. Consider this fragment:

```ruby
print "Hello.."
sleep 5
print "Goodbye!\n"
```

If you run this, both messages will appear at the same time, _after_ the sleep. The first output is not terminated by a
newline.

This can be fixed by calling `flush` to flush the output buffer. In this case, we use the stream
`$defout` (the default stream for all Kernel method output) as the receiver. It then behaves as we probably wanted, with
the first message appearing earlier than the second one.

```ruby
print "Hello"
STDOUT.flush
sleep 10
print "Goodbye!\n"
```

> Buffering can be turned off or on with the `sync=` method; the `sync` method lets us know the status:
> ```ruby
> buf_flag = $defout.sync   # true
> STDOUT.sync = false
> buf_flag = STDOUT.sync    # false
> ```


### Manipulating File Ownership and Permissions

To determine the owner and group of a file (which are integers), `File::Stat` has a pair of instance methods, `uid`
and `guid`, as shown here:

```ruby
data = File.stat("somefile")
owner_id = data.uid
group_id = data.gid
```

**File** has class and instance methods named `chown` to change the owner and group IDs of a file. The class method
accepts an arbitrary number of filenames. Where an ID is not to be changed, `nil` or `-1`
can be used:

```ruby
uid = 201
gid = 10
File.chown(uid, gid, "alpha", "beta")
f1 = File.new("delta")
f1.chown(uid, gid)
f2 = File.new("gamma")
f2.chown(nil, gid) # Keep original owner id
```

Likewise, the permissions can be changed by `chmod`. They are traditionally represented in octal, though they need not
be:

```ruby
File.chmod(0644, "epsilon", "theta")
f = File.new("eta")
f.chmod(0444)
```

A process always runs under the identity of some user (possibly **root**); as such, there is a user ID associated with
it. (Here, we are talking about the **effective** user ID.) We frequently need to know whether that user has permission
to read, write, or execute a given file.

```ruby
info = File.stat("/tmp/secrets")
rflag = info.readable?
wflag = info.writable?
xflag = info.executable?
```

Sometimes we need to distinguish between the effective user ID and the real user ID. The appropriate instance methods
are `readable_real?`, `writable_real?` and `executable_real?`.

We can test the ownership of the file as compared with the **effective user ID** (and group ID) of the current process.
The class `File::Stat` has the instance methods `owned?` and `grpowned?` to accomplish this.


### Retrieving and Setting Timestamp information

Each disk file has multiple timestamps associated with it (with some variations between OS'). The three timestamps that
Ruby understands are the modification time (the last time the file contents were changed), the access time (the last
time the file was read), and the change time
(the last time the file's directory information was changed).

The **File** class methods `mtime`, `atime` and `ctime` return the times without the file being opened or any **File**
object being instantiated.

```ruby
t1 = File.mtime("somefile")
# Thu Jan 04 09:03:10 GMT-6:00 2001
# ...
```

If there happens to be a **File** instance already created, the instance method can be used:

```ruby
myfile = File.new("somefile")
t1 = myfile.mtime
# ...
```

And if there happens to be a `File::Stat` instance already created, it has instance methods to do the same thing.

File access and modification times may be changed using the `utime` method. It will change the times of one or more
files specified. The times may be given either as **Time** objects or a number of seconds since the epoch:

```ruby
today = Time.now
yesterday = today - 86400
File.utime(today, today, "alpha")
File.utime(today, yesterday, "beta")

# If you want to leave one of the times unchanged:
mtime = File.mtime("delta")
File.utime(Time.now, mtime, "delta")
```


### Checking File Existence and Size

The `exist?` method in the **File** class provides a way to find out if a file exists.

```ruby
flag = File.exist?("LochNessMonster")
flag = File.exists?("UFO")
# exists? is a synonym for exist?
```

If you want to know whether a file has any contents, use the method `zero?` – it returns `true`
if the file is zero length and false otherwise:

```ruby
flag = File.zero?("somefile")
```

Conversely, the method `size?` returns either the size of the file in bytes if it is nonzero length, or the value `nil`
if it is zero length.


### Checking Special File Characteristics

Sometimes we want to know whether the stream is associated with a terminal. The IO class method
`tty?` tests for this (as does the synonym `isatty`)

```ruby
flag1 = STDIN.tty? # true
flag2 = File.new("diskfile").isatty # false
```

A stream can be a pipe or a socket. There are corresponding **FileTest** methods to test for these cases:

```ruby
flag1 = File.pipe?(myfile)
flag2 = File.socket?(myfile)
```

To check if a file is a directory use `directory?` and to check if a file is a file – `file?`.

There is also a **File** class method named `ftype`, which tells us what kind of thing a stream is; it can also be found
as an instance method in the **File::Stat** class. This method returns a string that has one of the following
values: `file`, `directory`, `blockSpecial`,
`characterSpecial`, `fifo`, `link`, or `socket`. (The string fifo refers to a pipe.)

A disk file may have symbolic or hard links that refer to it (on OS' supporting these features). To test whether a file
is actually a symbolic link to some other file, use the `symlink?` method. To count the number of hard links associated
with a file use the `nlink` method (found only in
**File::Stat**). A hard link is virtually indistinguishable from an ordinary file; in fact, it is an ordinary file that
happens to have multiple names and directory entries.

```ruby
File.symlink("yourfile", "myfile") # Make a link
is_sym = File.symlink?("myfile") # true
hard_count = File.new("myfile").stat.nlink # 0
```

> There are 3 methods in the **File::Stat** that give you even lower-level info about a file:
> `dev` – gives you an integer identifying the device on which the file resides
> `rdev` – returns an integer specifying the kind of device
> `ino` – for disk files, this gives you the starting **inode** number for the file.


### Working with Pipes

The class method `IO.popen` opens a pipe and hooks the process' standard input and output into the **IO** object
returned. Frequently we will have different threads handling each end of the pipe; here, we just show a single thread
writing and then reading:

```ruby
check = IO.popen("spell", "r+")
check.puts("'T was brillig, and the slithy toves'")
check.puts("Did gyre and gimble in the wabe.")
check.close_write
list = check.readlines
list.collect! { |x| x.chomp }
# list is now %w[brillig gimble gyre slithy toves wabe]
```

Note that the `close_write` call is necessary. If it were not issued, we wouldn't be able to reach the end-of-file when
we read the pipe.

There is a block form that works as follows:

```ruby
File.popen("/usr/games/fortune") do |pipe|
  quote = pipe.gets
  puts quote
end
```

If the string `-` is specified, a new Ruby instance is started. If a block is specified with this, the block is run as
two separate processes, rather like a fork. The child gets `nil` passed into the block, and the parent gets an **IO**
object with the child's standard input and/or output connected to it.

```ruby
IO.popen("-") do |mypipe|
  if mypipe
    puts "I’m the parent: pid = #{Process.pid}"
    listen = mypipe.gets
    puts listen
  else
    puts "I’m the child: pid = #{Process.pid}"
  end
end

# Prints:
#   I’m the parent: pid = 10580
#   I’m the child: pid = 10582
```

A pipe method also returns a pair of pipe ends connected to each other. In the following code example, we create a pair
of threads and let one pass a message to the other.

```ruby
pipe = IO.pipe
reader = pipe[0]
writer = pipe[1]

str = nil
thread1 = Thread.new(reader, writer) do |reader, writer|
  # writer.close_write 
  str = reader.gets
  reader.close
end

thread2 = Thread.new(reader, writer) do |reader, writer|
  # reader.close_read
  writer.puts("What hath God wrought?")
  writer.close
end

thread1.join thread2.join
puts str # What hath God wrought?
```


### Manipulating Pathnames

In manipulating pathnames, the first things to be aware of are the class methods **File.dirname**
and `File.basename`; these work like the UNIX commands of the same name and return the directory
name and the filename, respectively. If an extension is specified as a second parameter to **basename**,
that extensions will be removed.

```ruby
str = "/home/dave/podbay.rb"
dir = File.dirname(str)               # "/home/dave"
file1 = File.basename(str)            # "podbay.rb"
file2 = File.basename(str, ".rb")     # "podbay"
```

A comparable method is `File.split`, which returns these 2 components (directory and filename) in
a two-element array.

```ruby
info = File.split(str)                # ["/home/dave/", "podbay.rb"]
```

The `expand_path` class method expands a relative pathname, converting to an absolute path. If the
operating system understands such idioms as `~` and `~user`, these will be expanded also. The
optional second argument serves as a path to expand from, and is often used with the current file
path, `__FILE__`.

```ruby
Dir.chdir("/home/poole/personal/docs")
abs = File.expand_path("../../misc")            # /home/poole/misc
abs = File.expand_path("misc", "/home/poole")   # /home/poole/misc
```


### Command-Level File Manipulation

To delete a file, we can use `File.delete` or its synonym, `File.unlink`:

```ruby
File.delete("history")
File.unlink("toast")
```

To rename a file, we can use `File.rename` as follows:

```ruby
File.rename("Ceylon", "Sri Lanka")
```

File links (hard and symbolic) can be created using `File.link` and `File.symlink` respectively:

```ruby
File.link("/etc/hosts",  "/etc/hostfile")        # hard link
File.symlink("/etc/hosts",  "/tmp/hostfile")     # symbolic link
```

We can truncate a file to zero bytes (or any other specified number) by using the `truncate` instance
method:

```ruby
File.truncate("myfile", 1000)   # Now at most 1000 bytes
```

Two files may be compared by means of the `compare_file` method (alias `cmp`; there's also `compare_stream`):

```ruby
require 'fileutils'

same = FileUtils.compare_file("alpha", "beta")  # true
```

The `copy` method will copy a file to a new name or location. It has an optional flag parameter
to write error messages to standard error. The UNIX-like name `cp` is an alias:

```ruby
require 'fileutils'

# Copy epsilon to theta and log any errors
FileUtils.copy("epsilon", "theta", true)
```

A file may be moved with the `move` method (alias `mv`). Like `copy`, it also has an optimal verbose flag.

```ruby
require "fileutils"

FileUtils.move("/tmp/names", "/etc")    # Move to new directory
FileUtils.move("colours", "colors")     # Just rename
```

The `safe_unlink` method deletes the specified file or files, first trying to make the files writable
so as to avoid errors. If the last parameter is **true** or **false**, that value will be taken as the
verbose flag:

```ruby
require "fileutils"

FileUtils.safe_unlink("alpha", "beta", "gamma")
# Log errors on the next two files
FileUtils.safe_unlink("delta", "epsilon", true)
```

Finally, the `install` method basically does a `syscopy`, except that it first checks that the
file either does not exist or has different content.

```ruby
require "fileutils"

FileUtils.install("foo.so", "/usr/lib")
# Existing foo.so will not be overwritten
# if it is the same name as the new one.
```


### Copying a Stream

Use the class method `copy_stream` for copying a stream. All the data will be dumped from the
source to the destination. The source and destination **IO** objects or filenames. The third
(optional) parameter is the number of bytes to be copied (defaulting to entire source). The
fourth parameter is beginning offset (in bytes) for the source:

```ruby
src = File.new("garbage.in")
dst = File.new("garbage.out")
IO.copy_stream(src, dst)

IO.copy_stream("garbage.in", "garbage.out", 1000, 80)
# Copy 1000 bytes to output starting at offset 80
```


### Working with Temporary Files

The `new` method (alias `open`) takes an arbitrary name as a **seed** and concatenates it with
the process ID and a unique sequence number. The optional second parameter is the directory to be used;
it defaults to the value of environment variable **TMPDIR**, **TMP**, or **TEMP**, and finally
the value `"/tmp"`

> The resulting **IO** object may be opened and closed many times during the execution of the program.
> Upon termination of the program, the temporary file will be deleted.

The `close` method has an optional flag; if set to **true**, the file will be _deleted_ 
immediately after it is closed (instead of waiting until program termination). The `path`
method returns the actual pathname of the file, should you need it.


### Changing and Setting the Current Directory

The current directory may be determined by the use of `Dir.pwd` or its alias `Dir.getwd`.

The method `Dir.chdir` may be used to change the current directory. On Windows, the logged
drive may appear at the front of the string.

```ruby
Dir.chdir("/var/tmp")
puts Dir.pwd    # /var/tmp
```

This method also takes a block parameter. If a block is specified, the current directory is changed
only while the block is executed (and restored afterward).


### Changing the Current Root

On most UNIX variants, it is possible to change the current process's idea of where root or "slash"
is. This is typically done to prevent code that runs later from being able to reach the entire filesystem.
The `chroot` method sets the new root to the specified directory.

```ruby
Dir.chdir("/home/guy/sandbox/tmp")
Dir.chroot("/home/guy/sandbox")
puts Dir.pwd      # /tmp
```


### Iterating over Directory entries

The class method `foreach` is an iterator that successively passes each directory entry into
the block. The instance method `each` behaves the same way.

```ruby
Dir.foreach("/tmp") { |entry| puts entry }

dir = Dir.new("/tmp")
dir.each { |entry| puts entry }

# Output is the same for both loops – the names of all files and subdirectories in /tmp)
```


### Getting a list of Directory Entries

The class method `Dir.entries` returns an array of all the entries in the specified directory.
The current and parent directories are included. If you don't want these, you'll have to remove them
manually.


### Creating a Chain of Directories

Sometimes we want to create a chain of directories where the intermediate directories themseves don't
necessarily exist yet. At the UNIX command line, we would use `mkdir -p` for this.

In Ruby code, we can do his by using the `FileUtils.makedirs` method:

```ruby
require 'fileutils'
FileUtils.mkpath("/tmp/these/dirs/need/not/exist")
```


### Deleting a Directory Recursively

In the UNIX world, we can type `rm -rf dir` at the cmd line, and the entire subtree starting
with **dir** will be deleted. 

**Pathname** has a method called `rmtree` that will accomplish this. The **FileUtils** method
`rm_r` will do the same:

```ruby
require 'pathname'
dir = Pathname.new("/home/poole")
dir.rmtree
```


### Finding files and directories

The **Dir** class provides the `glob` method (aliased as `[]`), which returns an array of files
that match the give shell glob. In simple cases, this is often enough to find a specific file 
inside a given directory:

```ruby
Dir.glob("*.rb")          # All ruby files in the current directory
Dir["spec/**/*_spec.rb"]  # all files ending _spec.rb inside spec/
```

Contrary to its name, the find library can be used to do any task that requires traversing a 
directory and its children, such as adding up the total space taken by all files in a directory.


## Higher-Level Data access
 
Frequently, we want to store some specific data for later, rather than simply write bytes to
a file. In order to do this, we convert data from objects into bytes and back again, a process
called **_serialization_**. There are many ways to serialize data, so we will examine the simplest
and most common formats.

The **Marshal** module offers simple object persistence, and the **PStore** library builds
on that functionality. The YAML format (and Ruby library) provides another way to marshal
objects, but using plaintext that is easily human readable.


### Simple Marshaling

The simplest way to save an object for later use is by _marshaling_ it. The **Marshal**
module enables programs to **_serialize and unserialize_** Ruby objects into strings, and therefore
also files.

Storing data in this way can be extremely convenient, but can potentially be very dangerous. Loading
marshaled data can potentially be exploited to execute **any code**, rather than the
code of your program.

Never unmarshal data that was supplied by any external source, including users of your program.
Instead, use the YAML and JSON libs to safely read and write data provided by untrusted sources.

Marshaling also cannot dump all types of objects. Objects of system-specific classes cannot be
dumped, including **IO**, **Thread** and **Binding**. Anonymous and singleton classes also
cannot be serialized.

Data produced by `Marshal.dump` includes two bytes at the beginning, a major and minor version
number:

```ruby
Marshal.dump("foo").bytes[0..1]   # [4, 8]
```



