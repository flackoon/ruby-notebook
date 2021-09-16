# else block – in case none of the rescue blocks catch the exception
begin
  # Error-prone code...
rescue Type1 #...
rescue Type2 #...
else
  # Other exceptions...
end

# ensure block – code that will always be executed after all
begin
  # Error-prone code...
rescue
  # Handle exceptions
ensure
  # This code is always executed
end