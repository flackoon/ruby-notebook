## Missing methods

When a method is invoked (**my_object.my_method**), Ruby first searches for the named method according to 
this search order:
1. Singleton methods in the receiver **my_object** 
2. Methods defined in **my_object**’s class
3. Methods defined among **my_object**’s ancestors

If the method **my_method** is not found, Ruby searches for a method called **method_missing**. If this method 
is defined, it is passed the name of the missing method (as a symbol) and all the parameters that 
were passed to the nonexistent **mymethod**. This facility can be used for the dynamic handling of 
unknown messages sent at runtime.