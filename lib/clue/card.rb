module Clue
  class Card
    attr_reader :type, :name
    def initialize(type, name)
      @type = type
      @name = name.to_s
    end

    def to_s
      @name
    end

    def to_sym
      to_s.to_sym
    end
  end
end
