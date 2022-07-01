# Handling Errors

## Handling errors with return values

In programming languages that don't support exceptions, errors are generally handled by using a return value that
indicates failure. Ruby itself is written in **C**, and in C, functions that can fail will often use a return value that
is zero on success, and non-zero on failure. While Ruby has exceptions, there are instances where methods can fail and
this will occassionally return a value instead of raising an exception, even in cases where other programming langauges
raise exception.

In the case of a hash retrieval, for example, Ruby, compared to Pyton, is permissive, while Pyton is strict. Ruby would
not raise an error when retrieveing a non-existing key from a hash.

> In general, the Ruby principle for data access via `[]` is that an exception is not raised if there is a way the
> access would work if the receiver included different data.

<details>
  <summary>Different data in receiver example</summary>

  ```ruby
  ary = [1, 2, 3]
  ary[3]
  # => nil

  ary << 4
  ary[3]
  # => 4
  ```

  Accessing the `ary` array with an index that is beyond the bounds of the array returns `nil`, because if the array
  is expanded later, the same call will be within the bounds of the array, and will return the value at the index.

</details>


There are two primary benefits of using return values to signal errors:
- First, this approach offers much better performance than using exceptions, with pretty much the same performance in a
  successful case, and unintuitively, sometimes much better performance for an unsuccessful case than a successful one.
- Second, if the error is common, it's easier for the user to deal with it instead of forcing them to rescue an
  exception.

> The principle here is to be extra wary of using return values to indicate errors when the caller of the code doesn't
> need to use the return value of the method. It's usually better to raise an exception in this case.

## Handling errors with exceptions

In almost all cases, any unexpected or uncommon error should be raised as an exception and not handled via a return
value.

For example if you have a service **Authorizer** that has a method `check` that checks if the current user is authorized
to perform a specified action, it is certainly better for the method to raise an exception in situations where
authorization isn't granted because implemented in this manner, the usage of the method ensures any exceptions are
handled. If it otherwise returns `true` or `false`, and a new programmer doesn't understand the API, they may assume
that it handles the error by raising an exception and misuse the method by not handling all branches.

One of the principles is that when you are designing an API, you should not only design the API to be easy to use, but
you should also attempt to design the API to be difficult to misuse. This is the principle of **misuse resistance**. A
method that doesn't raise an exception for errors is easier to misuse than one that raises an exception for errors.

Another of the principles at play is that of fail-open versus fail-closed design.
In a **fail-open design**, if there is a problem with checking access, access is allowed.
In a **fail-closed design**, if there is a problem with checking access, access is not allowed.

In most cases involving security, fail-closed is considered to be the superior model.

<details>
  <summary>Different purposes methods example</summary>

  There might be a case where the user of the **Authorizer** does need a `true` or `false` value for whether an action
  is authorized. For example, to decide whether to show a link in a page or not. You don't want to write the following
  code:

  ```ruby
  begin
    Authorizer.check(current_user, :manage_users)
  rescue
    # don't show link
  else
    display_manage_users_link
  end
  ```

  This code uses exceptions for flow control, which is, in general, a bad approach.
  In a case like this it's usually better to have a method **Authorizer**.`allowed?` that returns `true` or `false`
  instead of raising an exception.

  The difference with the `check` method is that this one here has as `?` sign indicating that it returns a boolean
  value, which makes it much less likely to be misused. 

  With a method name such as `check`, it is ambiguous as to whether the method will return `true` or `false` or raise an
  exception, so misuse is much more likely to happen.

</details>

Another advantage of using exceptions to handle errors is that in many cases, higher-level code wants to handle the same
type of error the same way. So, instead of having one hundred different if-else expressions, you can have in a single
place in your application a rescue block that rescues the exception that the `check` method raises (for example).

## Considering performance when using exceptions

As mentioned, using return values instead of raising exceptions performs much better. For simpler methods, there isn't
a way to get the exception handling approach even close to the return value approach in terms of performance.

However, for methods that do even minimal processing, such as a single **String**`#gsub` call, the time for executig the
method is probably larger than the difference between the exception approach and the return value approach. Still for
the absolute maximum performance, you need to use the return value approach.

> Exceptions get slower in proportion to the size of the call stack.

The reason for this is that when you raise an exception the normal way, Ruby has to do a lot of work to construct a
backtrace for it. Ruby needs to read the entire call stack and turn it into an array of **Thread::Backtrace::Location**
objects.

If you wan to speed up the exception generation process, you can pass a third argument - an empty array - which is the
array to use for the backtrace.

```ruby
raise ArgumentError, "message",  []
```

This however would turn debugging into a nightmare. So best to avoid it.

## Retrying transient errors

There are some cases, when retrying errors makes sense. In case of a failed network request, for example. Ruby has a
built-in keyword for handling transient errors, which is `retry`:

<details>
  <summary>Retrying network error example</summary>

  ```ruby
  require 'net/http'
  require 'uri'

  uri = URI("http://example.local/file")
  begin
    response = Net::HTTP.get_response(uri)
    raise Net::HTTPBadResponse if response.code.to_i >= 400
  rescue SocketError, SystemCallError, Net::HTTPBadResponse
    retry
  end
  ```

  Couple of things to note in the above example:
  - We extracted the uri out of the loop to eliminate possible issues with its creation.
  - We are only retrying on specific errors occurrance
  - A valid response could as well be a failed response
  - Since we cannot use `retry` outside of a `rescue` block, we raise an error to trigger the retry

  What if your requirements change, and now you only want to retry on an HTTP client or server error, and not for other
  errors?

  The `redo` keyword comes to the rescue here. It's similar to `next`, but instead of going to the next block iteration,
  itrestarts the current block iteration.

  ```ruby
  require 'net/http'
  require 'uri'

  uri = URI("http://example.local/file")

  response = nil

  1.times do
    response = Net::HTTP.get_response(uri)

    redo if response.code.to_i >= 400
  end
  ```

</details>

> ...In general, procs and lambdas are among the more expensive objects instances to create, at least compared to other
> core classes.

## Understangind more advanced retrying

Use exponential backoff algorithm to schedule retries.

## Designing exception class hierarchies

It's best to raise an exception class related to your library, since it allows users of your library to handle the
exception differently from exceptions in other libraries.

> Your error classes should **always** inherit from **StandardError** and not from **Exception**. Subclassing
> **Exception** is very rare because it's subclasses are not caught by `rescue` clauses without arguments.

So best practices here are:
- Having a generic exception class for your lib
- When adding new exception classes to your library, always make them inherit the generic exception class. This way code
  that used to rescue the generic class will be backwards-compatible and users can change their code to rescue the newly
  added exception subclass
