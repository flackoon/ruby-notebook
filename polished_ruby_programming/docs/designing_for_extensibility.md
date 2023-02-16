# Designing for Extensibility

Most decent-sized libraries benefit benefit from being designed upfront for extensibility. The larger the library, the
more it benefits from extensible design.

## Using Ruby's extensibility features

One of Ruby's greatest aspects it that even if you don't explicitly design your library for extensibility, the language
itself offers ways to make the library extensible. Using the built-in language features directly makes it possible ot
extend a library, even it itself wasn't designed for extensibility.

All Ruby objects support extension by modification of the object's singleton class.

Commonly, libraries will define methods in classes. Let's say we are designing a Ruby library to manage books and users
for physical libraries. The physical library has many users, most of whom check out books on a regular basis. For each
user, we want to track the books they've checked out, and for each book, we want to know to whom the book is checked
out.

<details>
  <summary>Library class structure example</summary>

  ```ruby
  class Libry
    class User
      attr_accessor :books

      def initialize(id)
        @id = id
        @books = []
      end

      def checkout(book)
        @books << book
        book.checked_out_to = self
      end
    end

    class Book
      attr_accessor :checked_out_to

      def initialize(name)
        @name = name
      end

      def checkin
        checked_out_to.books.delete(self)
        @checked_out_to = nil
      end
    end
  end
  ```
</details>

This is fairly simple Ruby library design, with no features designed for extensibility. However, if you want to modify
the behavior of a particular book, you can always just define a method on the `Libry::Book` instance as shown:

```ruby
book = Libry::Book.new 'name'

def book.checked_out_to=(user)
  def user.checkout(book)
    nil
  end

  nil
end
```

The `checked_out_to=` method internally creates a singleton class for the book instance and an instance method in the
singleton class. Maybe this book is cursed and checking it out will curse the user who does that. **Libry** doesn't
support cursing users yet, but you can have the curse make it so the user cannot check out another book.

This approach works, and you can extend your library to support book and user cursing this way, but it's considered a
bit of a code smell to manually define singleton methods on objects, at least if you are defining the same method on
multiple objects. The more idiomatic way of doing this in Ruby is to use modules:

<details>
  <summary>Cursed module example</summary>

  ```ruby
  module Cursed
    module Book
      def checked_out_to(user)
        user.extend User
        super
      end
    end

    module User
      def checkout(book)
        nil
      end
    end
  end
  ```

  Cursing a book is now as simple as extending the book with the `Cursed::Book` module.

  ```ruby
  user = Libry::User.new 3
  user.checkout Libry::Book.new('x')

  book = Libry::Book.new 'name'
  book.extend Cursed::Book
  user.checkout book
  user.books.length # => 2

  user.checkout Libry::Book.new('y')
  user.books.length # => 2
  ```

</details>

## Designing plugin systems

Having a defined plugin system for a library can be a huge advantage. Libraries that don't have a plugin system usually
handle extensions to the library in an ad-hoc manner that differs per extension. With a plugin system, extensions to the
library operate in a uniform manner for each extension.

### Designing a basic plugin system

The first decision point when designing a plugin system is to decide whether you want to use an include-based or
prepend-based plugin system. With an include-based plugin system, all methods are in modules that are included in the
classes in the library, and the classes themselves are empty. With a prepend-based plugin system, methods are defined
inside classes, and plugins contain modules that are prepended to the classes.

> In general, an include-based plugin system is better.

With an include-based system, a user of the library can add normal instance methods to the class and call `super` to get
the default behavior. With a prepend-based system, methods a user defines directly in the class may have no effect;
users must prepend a module to the class with the method they want to define after they've already loaded all of the
system plugins, or otherwise a plugin can override the user's custom methods.

<details>
  <summary>Libry include-based system plugin rewrite</summary>

  ```ruby
  class Libry
    class Book; end
    class User; end
  ```

  The core of the library will itself be a plugin.

  ```ruby
    module Plugins
      module Core
  ```

  In our case, we probably want to allow plugins to modify both `Libry::Book` and `Libry::User`. We'll put the methods
  for `Libry::Book` in a `BookMethods` module.

  ```ruby
        module BookMethods
          attr_accessor :checked_out_to

          def initialize(name)
            # ...
          end

          def checkin
            # ...
          end
        end
  ```

  And the methods for `Libry::User` in a `UserMethods` module:

  ```ruby
        module UserMethod
          attr_accessor :books

          def initialize(id)
            # ...
          end

          def checkout(book)
            # ...
          end
        end
      end
  ```

  Now, all we need is a method that loads plugins to wire everything up. We'll add the `Libry.plugin` method for this.

  ```ruby
    def self.plugin(mod)
      if defined?(mod::BookMethods)
        Book.include(mod::BookMethods)
      end
      if defined?(mod::UserMethods)
        User.include(mod::UserMethods)
      end
    end

    plugin Plugins::Core
  end
  ```

</details>

If you only have a single plugin, it'll always look like this added complexity instead of removing it. You should only
implement a plugin system in cases where the benefit of the plugin system is worth the extra cognitive overhead.

The advantage of the plugin system is that plugins can be easily and straightforwardly loaded.

<details>
  <summary>Cursing module example</summary>

  ```ruby
  class Libry
    module Plugins
      module Cursing
        module BookMethods
          def curse!
            # ...
          end

          def checked_out_to=(user)
            # ...
          end
        end

        module UserMethods
          def curse!
            # ...
          end

          def checkout(book)
            # ...
          end
        end
      end
    end
  end
  ```

</details>

Then it all boils down to 1 line when a user wants to include this plugin.

```ruby
Libry.plugin Libry::Plugins::Cursing
```

### Handling changes to classes

What if you want to add a plugin to keep track of all books or users? This isn't related to a particular Book or
User instance, it's a class-level concern. For tracking class-level information, you wouldn't want to include a module
in neither of the classes, you would want to extend them with a module for that behavior.

<details>
  <summary>Adding tracking plugin to the system</summary>

  Let's start by modifying the `Libry.plugin` method to support extending the classes with a module in addition to
  including a module in the class.

  ```ruby
  class Libry
    def self.plugin(mod)
      # same as before

      if defined?(mod::BookClassMethods)
        Book.extend mod::BookClassMethods
      end
      if defined?(mod::UserClassMethods)
        User.extend mod::UserClassMethods
      end
    end
  end
  ```

  This checks whether the plugin module contains the `*ClassMethods` modules for defining class-level behavior. If so,
  it extends them.

</details>
