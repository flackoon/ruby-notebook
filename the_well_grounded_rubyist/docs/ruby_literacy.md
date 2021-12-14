# Ruby literacy

1. [Basic Ruby language literacy](#basic-ruby-language-literacy)\
   1.1. [Feeding the program to Ruby](#feeding-the-program-to-ruby)
2. [Anatomy of the Ruby installation](#anatomy-of-the-ruby-installation)\
   2.1. [The Ruby standard library subdirectory (RbConfig::CONFIG["rubylibdir"])](#the-ruby-standard-library-subdirectory-rbconfigconfigrubylibdir)\
   2.2. [The C extensions directory (RbConfig::CONFIG["archdir"])](#the-c-extensions-directory-rbconfigconfigarchdir)\
   2.3. [Standard Ruby gems and the gems directory](#standard-ruby-gems-and-the-gems-directory)
3. [Ruby extensions and programming libraries](#ruby-extensions-and-programming-libraries)\
   3.1. ["Load"-ing a file in the default load path](#load-ing-a-file-in-the-default-load-path)\
   3.2. ["Require"-ing a feature](#require-ing-a-feature)\
   3.3. [require_relative](#require_relative)


## Basic Ruby language literacy

### Feeding the program to Ruby

Conveniently, the Ruby interpreter can check programs for syntax errors without running the programs. It reads through
the file and tells you whether the syntax is okay. To run a syntax check on your file, do this:

`$ ruby -cw filename.rb`

The `-cw` command-line flag is shorthand for 2 flags: `-c` and `-w`. The `-c` flag means _check for syntax errors_. The
`-w` flag activates a higher level of warning: Ruby will fuss at you if you've done things that are legal in Ruby but are
questionable on grounds other than syntax.


## Anatomy of the Ruby installation

### The Ruby standard library subdirectory (RbConfig::CONFIG["rubylibdir"])

In rubylibdir you'll find program files written in Ruby. These files provide standard library facilities, which you can
require from your own programs if you need the functionality they provide.    


### The C extensions directory (RbConfig::CONFIG["archdir"])

Usually located one level down from rubylibdir, archdir contains architecture-specific extensions and libraries. The files
in this directory typically have names ending in .so, .dll, or .bundle (depending on your hardware and OS). These files
are C extensions: binary, runtime-loadable files generated from Ruby's C-language extension code, compiled into binary
form as part of the Ruby installation process.

These files can be loaded in your programs, despite not being human-readable. What is installed in that directory depends
on which extensions were compiled upon installation, which in turn depends on a mixture of what the person doing the
compiling asked for and which extensions Ruby was able to compile.


### Standard Ruby gems and the gems directory

The RubyGems utility is the standard way to package and distribute Ruby libraries. During a Ruby installation, several
gems are installed for you.

When you install gems, the unbundled library files land in the same gems directory as the preceding gems. This directory
isn't listed in the config data structure, but it's usually at the same level as site_ruby; if you've found site_ruby, 
look for a directory called "gems" next to it. 

####**Working with multiple versions of Ruby**

Installing Ruby multiple times (different versions) on one machine may affect what's listed in your gem directory in your
Ruby installation.

This is because Ruby takes advantage of RubyGems mechanics to only install what's necessary. The first time Ruby is installed,
all the standard library gems will be installed. When you install the next version of the language, Ruby will check first to 
see which of the gems are installed. If, for example, it sees that a minimum acceptable version of rake is already
installed, it won't proceed to install another rake gem.

The result should be unnoticeable when you're interacting with Ruby. When inspecting your Ruby installation, however,
you mau notice differences from what's described here. Using rake as an example again, your second Ruby installation may
not have rake listed in the gems directory and may not have the **rake** utility listed in the **bindir**. These 
libraries and tools are still available for your use, but they may reside in the gem directory of bindir of a different
Ruby version of your machine.


## Ruby extensions and programming libraries

The extensions that ship with Ruby are usually referred to collectively as the **standard library**. The standard library
includes extensions for a very wide variety of projects and tasks: database management, networking, specialized math,
XML processing and many more. 

The key to using extensions and libraries is the `require` method, along with its near relation `load`. These methods
allow you to load extensions at runtime, including extensions you write yourself.


### "Load"-ing a file in the default load path

The Ruby interpreter's load path is a list of directories in which it searches for files you ask it to load. You can see
the names of these directories by examining the contents of the special global variable `$:`. What you see depends on 
what platform you're on. 

You can navigate relative directories in your `load` commands with the conventional double-dot "directory up" symbol:

`load "../extras.rb"`

> Keep in mind that `load` is a method, and it's executed at the point where Ruby encounters it in your file. Ruby 
> doesn't search the whole file looking for load directives; it finds them when it finds them. This means you can load files
> whose names are determined dynamically during runtime. You can even wrap a `load` call in a conditional statement.

A call to `load` always loads the file you ask for, whether you've loaded it already or not. If a file changes between
loadings, anything in the new version of the file that rewrites or overrides anything in the original version takes
priority. This can be useful, especially if you're in an **irb** session and modifying a file in an editor at the same
time – you can determine the effect of your changes immediately.


### "Require"-ing a feature

One major difference between `load` and `require` is that `require`, if called more than once with the same arguments
doesn't reload files it's already loaded. 

`require` is more abstract than `load`. Strictly speaking, you don't require a _file_; you require a **feature**. And 
typically, you do so without even specifying the extension on the filename. 


### require_relative

There's a third way to load files: `require_relative`. This command loads features by searching relative to the directory
in which the file from which it's called resides.


## Out-of-the-box Ruby tools and applications

When you install Ruby, you get a handful of important command-line tools, which are installed in whatever directory is
configured as bindir.

- **ruby** – The interpreter
- **irb** – The interactive Ruby interpreter
- **rdoc** and **ri** – Ruby documentation tools 
- **rake** – Ruby make, a task-management utility
- **gem** – A Ruby library and application package-management utility
- **erb** – A templating system


### Interpreter command-line switches

#### Check syntax (-c)

The `-c` switch tells Ruby to check the code in one or more files for syntactical accuracy without executing the code.


#### Turn on warnings (-w)

This flag causes the interpreter to run in warning mode. It's Ruby's way of saying, "What you've done is syntactically
correct, but it's weird. Are you sure you meant to do that?"


#### Execute literal script (-e)

The `-e` switch tells the interpreter that the command line includes Ruby code in quotation marks, and that it should 
execute that actual code rather than execute the code contained in a file.

`$ ruby -e 'puts "David A. Black".reverse'`

If you want to feed a program with more than one line to the -e switch, you can use literal line breaks or semicolons to
separate lines.


#### Run in line mode (-l)

The `-l` switch causes every string output by the program to be placed on a line of its own, even if it normally wouldn't
be. Usually this means that lines that are output using `print`, rather than `puts`, and that therefore don't automatically
end with a newline character, now end with a newline.

If a line ends with a newline character _already_, running it through `-l` adds _another_ newline.


#### Require named file or extension (-rname)

The `-r` switch calls `require` on its argument; `ruby – rscanf` will require **scanf** when the interpreter starts up.
You can put more than one `-r` switch on a single command line.


#### Run in verbose mode (-v, --verbose)

Does two things: prints out information about your Ruby version, and then turns on the same warning mechanism as the `-w`
flag.


#### Combining switches (-cw)

You can also combine two or more in a single invocation of Ruby.

`$ ruby -cw filename`

