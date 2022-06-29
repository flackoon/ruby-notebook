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
