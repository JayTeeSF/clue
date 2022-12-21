module Clue
  class Freq
    DEFAULT_SAMPLE_COUNT = 10_000.freeze
    def initialize(input_array, sample_count=nil)
      @input_array = input_array
      @sample_count = sample_count || DEFAULT_SAMPLE_COUNT
    end

    # map(frequencies(input_array))
    def map_frequencies
      # the 'm' starts off with whatever was passed to "reduce" (originally an empty Hash / Object)
      # in each iteration m gets updated
      # at the end of each iteration the "new" m is used for the next iteration
      # frequencies (see method definition below) returns an array that contains roll_counts for one or more "value(s)"
      @map_frequencies = frequencies.reduce(Hash.new(0)) {|m, (value, roll_count)|
        #puts("m: #{m.inspect}; value: #{value.inspect}, roll_count: #{roll_count.inspect}")
        m[value] = Float(roll_count) / @sample_count
        m 
      }
    end

    # @sample_count says how-many times to run this loop
    #  e.g.
    #  if @sample_count contains the number 3, then @sample_count.times says
    #  run the loop (each_with_object...) 3 time
    #
    # @input_array is all _possible_ values that *could* be generated
    #
    # @input.sample says randomly pick a value from the @input_array
    #
    # each_with_object is similar to calling "reduce" above...
    #   it starts with an initial object (i.e. an empty Hash)
    #   but instead of the initial object being the _first_ argument passed to the "block" {|<args>| ...}
    #   it's the last-argument (which we subjectively named "freq")
    #   by using an underscore, we say we are ignoring the actual values passed-in from @sample_count.times
    #   otherwise, that would just be like a counter 0, 1, 2, 3...
    #   with-in each loop we store the number of times each value gets (randomly) generated
    #   What happens in the first loop, we add 1 to the exiting value in the hash
    #   Shouldn't the existing value be nil?!?!
    #   No ...because instead of just starting with {} or Hash.new, we used Hash.new(0) ...which says every new
    #   entry to this hash will automatically have a value of 0
    def frequencies
      @frequencies ||= @sample_count.times.each_with_object(Hash.new(0)) {|_, freq|
        freq[@input_array.sample] += 1
      }
    end
  end
end
