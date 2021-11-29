## Ruby syntax tricks

1. ####What is false

    In Ruby, the value **false** cannot be represented as zero, a null string, a null char and so on..
In Ruby all of these are **true**. In fact, **_everything_** is **true** except false and nil.

2. ### loop's index variable 
   .. cannot quite be modified at will. Such modification simply does **affect** the loop behavior.

3. ### the ``===`` (case equality | relationship) operator
   - This operator is used in the `case` statement.
   - It it **not** the same as the `equality operator (==)`. The relationship operator is defined differently 
   for different classes and, for a given class, may behave differently for different operand types
   passed to it.
   
4. ### The `||=` operator
   Use this operator to assign a value to a variable only if it does **not** have one already.\
   Example: `x ||= 5`\
   >Beware that values **nil** and **false** will be **overwritten**. 
   
5. ### The pound `#` notation
   is sometimes used to indicate an **instance** method – for example, we use `File.chmod` to denote the
   class method `chmod` of class `File`, and we use `File#chmod` to denote the instance method that has
   the same name. This notation is `not` part of Ruby syntax but only Ruby folklore.

6. ### The `yield` keyword
   It comes from CLU and is used **within an iterator** to `invoke the block` with which the iterator
   is called. It does **NOT** mean "yield" as in producing a result or returning a value.

7. ### "bare" scope operator
   The "bare" scope operator has an implied **Object** before it.\
   Therefore, `::Foo` means `Object::Foo`

8. ### `fail` is an alias for `raise`

9. ### Creation of a singleton class
   This is done with the `<<` symbol:
   ```ruby
   class << platypus
    # ...
   end
   ```
   
10. ### The @variable 
   By default we define **instance** variables using the `@` prefix. But when defined outside any method,
   such variable is actually a **class instance** variable.
   ```ruby
   class MyClass
      @x = 1  # A class instance variable
      @y = 2  # Another one
   
      def my_method
        @x = 3 # An instance variable
        # Note that @y is not accessible here
      end
      
      def self.my_other_method # Class method
        puts @x, @y # @x and @y are accessible here
      end
   end
   ```   
   In this code example, the `@y` variable is an attribute of the class object **MyClass**, which is 
   instance of the class `Class`. Class instance variables cannot be referenced **from within instance**
   methods and, in general, are not very useful.

11. ### Multiple assignment
   ```ruby
   x = y = z = 0    # All are now zero
   a = b = c = []   # Danger! a, b and c now all refer to the SAME empty array
   
   x = 5 
   y = x += 2       # Now x and y are both 7
   ```

   