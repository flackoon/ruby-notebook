# Scripting and System Administration

1. [Running External Programs](#running-external-programs)\
  1.1. [Using system and exec](#using-system-and-exec)\
  1.2. [Capturing Command Output](#capturing-command-output)\
  1.3. [Manipulating Standard Input and Output](#manipulating-standard-input-and-output)
2. [Command-Line Options and Arguments](#command-line-options-and-arguments)\
  2.1. [Working with **ARGV**](#working-with-argv)\
  2.2. [Working with ARGF](#working-with-argf)\

## Running External Programs

A language can't be a glue language unless it can run external programs. Ruby offers more than one way to do this.


### Using `system` and `exec`

The `system` method (in **Kernel**) is equivalent to the C call of the same name. It will execute the given command in
a subshell. 

```ruby
system("date")
# Output goes to stdout as usual...
```

Additional parameters, if present, will be used as a list of arguments; in most cases, the arguments can also be specified
as part of the command string with the same effect. The only difference is that filename expansion is done on the first string
but not on the others.

```ruby
system("rm", "/tmp/file1")
system("rm /tmp/file1")
# Both work fine

# However, there's a difference down here
system("echo *")    # Prints list of all files
system("echo", "*") # Prints an asterisk

# More complex command lines also work
system("ls -l | head -n 1")
```

> If you want to capture the output, `system` isn't the right way.

The `exec` method behaves much the same as `system`, except that new process actually replaces the current one. Thus,
any code following the `exec` won't be executed.

```ruby
puts "Here's a directory listing:"
exec("ls", "-l")

puts "This line is never reached!"
```


### Capturing Command Output

The simplest way to capture command output is to use the _backtick_ (also called _backquote_ or _grave accent_) to delimit the 
command. 

```ruby
listing = `ls -l`  # Multiline lines in one string
now = `date`       # "Mon Mar 12 16:50:11 CST 2001"
```

The generalized delimiter `%x` calls the backquote operator (which is really a **kernel** method). It works essentially 
the same way.

```ruby
listing = %x(ls -l)
```

The `%x` form is often useful when the string to be executed contains characters such as single and double quotes.

Because the backquote method really is (in a sense) a method, it is possible to override it. 

```ruby
alias old_execute `
def `(cmd)
  out = old_execute(cmd)    # call the old backtick method
  out.split("\n")           # Return an array of strings
end
```

> The functionality of `%x` is affected when we perform this redefinition.


### Manipulating Processes

The principal way to create a new process is the `fork` method, which takes its name from the UNIX tradition's idea of a
fork in the path of execution, like a fork in the road. (Note, however, that _Ruby does not support the `fork` method
on Windows platforms._)

The `fork` method in **Kernel** (also found in the **Process** module) shouldn't, of course, be confused with the **Thread**
instance method of the same name.

There are two ways to invoke the `fork` method. The first is the more UNIX-like way:
Simply call it and test its return value: If that value is `nil`, we are in the child process; otherwise, we execute the
parent code. The value returned to the parent is actually the process ID of the child:

```ruby
pid = fork
if (pid == nil)
  puts "Child process"
else
  puts "Parent"
end

# This example is unrealistic. The output might be interleaved, or the parent's output might appear first. For the
# purpose of the example, it's irrelevant.
```

It should also be noted that the child process might outlive the parent. We've seen that this isn't the case with
Ruby threads, but system-level processes are entirely different.


The second form of `fork` takes a block. The code in the block compromises the child process. 

```ruby
pid = fork do
  puts "I'm the child process"
end

puts "I'm the parent process"
```

The **pid** is still returned of course.

When we want to wait for a process to finish, we can call the `wait` method in the **Process** module. It waits for any
child to exit and returns the process ID of that child. The `wait2` method behaves similarly except that it returns a 
two-value array consisting of the pid and a **Process::Status** object with the pid and exit status code.

```ruby
pid1 = fork { sleep 2; exit 3 }
pid2 = fork { sleep 1; exit 3 }

pid2_again = Process.wait       # Returns pid2
pi1_and_status = Process.wait2  # Returns [pid1, #<Process::Status exit 3>]
```

To wait for a specific child, use `waitpid` or `waitpid2`.

```ruby
pid1 = fork { sleep 2; exit 3 }
pid2 = fork { sleep 1; exit 3 }

sleep 3  # Give the child process time to finish.

pid1_again = Process.waitpid(pid1, Process::WHOHANG)
```

If the second parameter is unspecified, the call might block (if no such child exists). It might be ORed logically with
**Process::WUNTRACED** to catch child processes that have been stopped. This second parameter is OS sensitive; experiment
before relying on its behavior.

The `exit!` method exits immediately from a process (bypassing any exit handlers). Any given integer will be used as the
exit code, but the default is 1 (not 0);

```ruby
pid1 = fork { exit! }    # Return 1 exit code
pid2 = fork { exit! 0 }  # Return 0 exit code
```

The `pid` and `ppid` methods will return the process ID of the current process and the parent process, respectively.

```ruby
proc1 = Process.pid
fork do
  if Process.ppid = proc1
    puts  "proc1 is my parent" # Prints this message
  else
    puts "What's going on?"
  end
end
```

The `kill` method can be used to send a UNIX-style signal to a process. The first parameter can be an integer, a POSIX
signal name including the `SIG` prefix, or a non-prefixed signal name The second parameter represents a pid; if it is 
zero, it refers to the current process:

```ruby
Process.kill(1, pid1)         # Send signal 1 to process pid1
Process.kill("HUP", pid2)     # Send SIGHUP to pid2
Process.kill("SIGHUP", pid2)  # Send SIGHUP to pid3
Process.kill("SIGHUP", 0)     # Send SIGHUP to self
```

The `Kernel.trap` method can be used to handle such signals. It typically takes a signal number or name and a block to
be executed.

```ruby
trap(1) do
  puts "OUCH!"
  puts "Caught signal 1"
end

Process.kill(1, 0)  # Send to self
```

The `trap` method can be used to allow complex control of yoiur process. For more information, consult Ruby and UNIX
references on process signals.

The **Process** module also has methods for examining and setting such attributes as userid, effective userid, 
priority, and others. 


### Manipulating Standard Input and Output

The **Open3** library contains a method called `popen3` that will return an array of three **IO** objects. These objects
correspond to the standard input, standard output, and standard error for the process kicked off by the `popen3` call.

```ruby
require 'open3'

filenames = %w[file1 file2 this that another one_more]
output, errout = [], []

Open3.popen3("xargs", "ls", "-l") do |inp, out, err|
  filenames.each { |f| inp.puts f }   # Write to the process's stdin
  inp.close                           # Close is necessary!
  
  output = out.readlines              # Read from its stdout
  errout = err.readlines              # Also read from its stderr
end

puts "Send #{filenames.size} lines of input."
puts "Got back #{output.size} lines from stdout"
puts "and #{errout.size} lines from stderr."
```

The contrived example does an `ls -l` on each of the specified filenames and captures the standard output and standard
output and standard error separately. Not that closing the input is needed so that the subprocess will be aware that the
input is complete. Also note the **Open3** uses `fork`, which doesn't exist on Windows; on that platform, you will have 
to use the `win32-open3` library.


## Command-Line Options and Arguments

Rumors of the death of the command line are greatly exaggerated. Although we live in the age of the GUI, every day 
thousands of us use older text-based interfaces for one reason or another.


### Working with **ARGV**

The global constant **ARGV** represents the list of arguments passed to the Ruby program via the command line. This is
essentially just an array:

```ruby
n = ARGV.size
argstr = %{"#{ARGV * ', '}"}
puts "I was given #{n} arguments..."
puts "They are: #{argstr}"
puts "Note that ARGV[0] = #{ARGV[0]}"
```

Assume that we invoke this program with the argument string `red green blue` on the command line. 

```
I was given 3 arguments...
They are "red, green, blue"
Note that ARG[0] = red
```

Where **ARGV** in some languages would also supply a count of arguments, there is no need for that in Ruby because
that information is part of the array.

Another thing that might trip up old-timers is the assignment of the zeroth argument to an actual argument (rather
than, for example, the script name). The arguments themselves are zero-based rather than one-based as in C and the 
various languages.


### Working with **ARGF**

The special global constant **ARGF** represents the pseudo-file resulting from a concatenation of every file named on
the command line. It behaves like an **IO** object in most ways. When you have a "bare" input method (without a receiver),
you are typically using a method mixed in from the **Kernel** module. (Examples are `gets` and `readlines`.) The actual
source of input will default to `STDIN` if no files are on the command line. If there are files, however, input will be
taken from them. End of file will of course be reached only at the end of the last line.

If you prefer, you can access `ARGF` explicitly using the following fragment:

```ruby
# Copy named files to stdout, just like 'cat'
puts ARGF.readlines
```

Perhaps contrary to expectations, end of file is set after each file. The previous code fragment will output all the
files. This one will output only the first:

```ruby
puts ARGF.gets until ARGF.eof?
```

> The input isn't simply a stream of bytes flowing though our program; we can actually perform operations such as `seek`
> and `rewind` on `ARGF` as though it were a "real file".

There is also a `file` method associated with `ARGF`; it returns an **IO** object corresponding to the file currently 
being processed. A such, the value it returns will change as the files on the command line are processed in sequence.

If you don't want command-line arguments to be interpreted as files don't use the "bare" (receiverless) call of the 
input methods. If you want to read standard input, call methods on `STDIN`, and all will work as expected.

