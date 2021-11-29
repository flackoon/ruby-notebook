require 'thread'

def threaded_max(interval, collections)
  threads = []

  collections.each do |col|
    threads << Thread.new do
      me = Thread.current
      me[:result] = col.first
      col.each do |n|
        puts "inserting #{n} because it's bigger than #{me[:result]}" if n > me[:result]
        me[:result] = n if n > me[:result]
      end
    end
  end

  sleep(interval)

  threads.each { |t| t.kill }
  results = threads.map { |t| t[:result] }
  results.compact.max   # Max be nil
end


collections = [
  [ 1, 25, 3, 7, 42, 64, 55 ],
  [ 3, 77, 1, 2, 3, 5, 7, 9, 11, 13, 102, 67, 2, 1],
  [ 3, 33, 7, 44, 77, 92, 10, 11]]

biggest = threaded_max(0.5, collections)
puts biggest