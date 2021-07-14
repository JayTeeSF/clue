module Clue
  class Freq
    DEFAULT_SAMPLE_COUNT = 10_000.freeze
    def initialize(input_array, sample_count=nil)
      @input_array = input_array
      @sample_count = sample_count || DEFAULT_SAMPLE_COUNT
    end

    # map(frequencies(input_array))
    def map_frequencies
      @map_frequencies = frequencies.reduce(Hash.new(0)) {|m, (key, roll_count)|
        #puts("m: #{m.inspect}; key: #{key.inspect}, roll_count: #{roll_count.inspect}")
        m[key] = Float(roll_count) / @sample_count
        m 
      }
    end

    def frequencies
      @frequencies ||= @sample_count.times.each_with_object(Hash.new(0)) {|_, freq|
        freq[@input_array.sample] += 1
      }
    end
  end
end
