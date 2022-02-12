require 'pry'

# Interpreting an in memory database

# Generating sample data
album_infos = 100.times.flat_map do |i|
  10.times.map do |j|
    ["Album #{i}", j, "Track #{j}"]
  end
end

# One approach for handling this is to populate 2 hashes, one keyed by album name, and one by an array of the album name
# and track number.

album_artists = {}
album_track_artists = {}

album_infos.each do |album, track, artist|
  (album_artists[album] ||= []) << artist
  (album_track_artists[[album, track]] ||= []) << artist
end

album_artists.each_value(&:uniq!)

# With this approach, looking up values is fairly staightforward, and just involves looking up in the appropriate hash
# with the appropriate key:

lookup = ->(album, track=nil) do
  if track
    album_track_artists[[album, track]]
  else
    album_artists[album]
  end
end
# An alternative approach would be to use a nested hash approach, with each album having a hash of tracks:
albums = {}
album_infos.each do |album, track, artist|
  ((albums[album] ||= {})[track] ||= []) << artist
end


# With this approach, looking up values is more complex, especially in the case where a track number is not provided,
# and you have to dynamically create the list:
lookup = ->(album, track = nil) do
  if track
    albums.dig(album, track)
  else
    a = albums[album].each_value.to_a
    a.flatten!
    a.uniq!
    a
  end
end

# In general the first approach using multiple hashes is going to take significantly more memory than the second one if
# there's a large number of albums, but it will have a much better lookup performance for albums. The first approach
# will also take much more time to populate the data structure. The first approach is much lighter on memory and has
# better lookup performance for albums with tracks as it avoids an array allocation, but will exhibit a far more
# inferior performance for albums.

# If you know in advance that the track number was an integer between 1 and 99. You could use that information to design
# a different approach. You could still have a single of hash keyed by album name, with a value being an array
# containing arrays of artist names for each track. Since tracks only go from 1 to 99, you could use the 0 index in the
# array to store all artist names for the album. 

albums = {}
album_infos.each do |album, track, artist|
  album_array = albums[album] ||= [[]]
  album_array[0] << artist
  (album_array[track] ||= []) << artist
end

albums.each_value do |array|
  array[0].uniq!
end

# This approach is more memory-efficient than either of the previous approaches, and looking up values is very simple
# and never allocates an object.

lookup = ->(album, track=0) do
  albums.dig(album, track)
end

# Compared to the previous two approaches, this approach uses about the same amount of memory as the nested hash
# approach. It takes slightly more time to populate compared of the nested hash approach. It is almost as fast as the
# two hash approach in terms of lookup performance for albums, and is the fastest approach for lookup performance by
# albums with tracks.

# Maybe the needs of your approach change, and now you need a feature that allows users to enter a list of artist names
# and a list of artist names, and will return an array with only the artist names that he application knows are on one
# of the albums. One way to handle this is to store the artists in an array:

album_artists = album_infos.flat_map(&:last)
album_artists.uniq!

# The lookup can use an array intersection to determine the values:

lookup = ->(artists) do
  album_artists & artists
end

# The problem with this approach is Array#& uses a linear search of the array, so this approach is very slow for a large
# number of artists. 
# A better performing approach would be to use a has, keyed by the artist name:

album_artists = {}
album_infos.each do |_, _, artist|
  album_artists[artist] ||= true
end

# The lookup can use the hash to filter the values in the submitted array:

lookup = ->(artists) do
  artists.select do |artist|
    album_artists[artist]
  end
end


# This approach performs much better. The code isn't as simple, though it isn't too bad.
# The good news is that it can be simplified using the Set class.

album_artists = Set.new(album_infos.flat_map(&:last))

# You don't need to manually take the array unique, because the set automatically ignores duplicate values. The lookup
# code can stay exactly the same as the array case:

lookup = ->(artists) do
  album_artists & artists
end

# Of the 3 approaches, the hash approach is the fastest to populate and the fastest to look up. The Set approach is much
# faster to look up than the array approach, but still significantly slower than hash. Set is actually implemented using
# a hash internally, so in general, it will perform worse than a hash directly. As a general rule, you should only use a
# set for code that isn't performance-sensitive and you would like to use a nicer API. For any performance-sensitive
# code, you should prefer using a hash directly.

