require 'set'
# TBD: consider adding arrays of Card(s) to each Player instance
# require_relative "card"

module Clue
  class Player
    TXT_COL_SIZE = 11.freeze
    attr_reader :name, :does_not_have, :has, :col_size
    def initialize(name, col_size=nil)
      @name = name.to_s
      @col_size = col_size || TXT_COL_SIZE
      @does_not_have = Set.new([])
      @has = Set.new([])
      @has_at_least_one_of = Set.new([])
    end

    def clear_possibilities
      @has_at_least_one_of.clear
    end

    def possibilities
      @has_at_least_one_of
    end

    def possibilities_to_s
      list = possibilities.reduce([]) { |ary, possibility|
        ary << "who: #{(possibility[:who]||'').ljust(col_size,' ')} where: #{(possibility[:where]||'').ljust(col_size,' ')} what: #{(possibility[:what]||'').ljust(col_size, ' ')}";
        ary
      }
      list.join("\n\t\t")
    end

    # trim by what we know we do NOT have
    def trim_by_what_is_known(card)
      does_not_have.include?(card) ? nil : card
    end

    # prefilter these cards against all other known cards:
    # board_cards,
    # your_cards,
    # revealed_cards, <-- distinguish this players own reveal cards!!!
    # does_not_have filter too...
    #
    # Simplified:
    # JUST FILTER THESE BY YOUR OWN DONT_HAVE SET <-- which automatically gets updated when other players reveal, or the board, or I have something!
    def has_at_least_one_of(who_card, what_card, where_card)
      who_card = trim_by_what_is_known(who_card)
      what_card = trim_by_what_is_known(what_card)
      where_card = trim_by_what_is_known(where_card)

      trimmed_cards = [who_card, what_card, where_card].compact
      num_trimmed_cards = trimmed_cards.size
      if 1 == num_trimmed_cards
        warn("ONLY one card, so user MUST have this card: #{timmed_cards.map(&:name)}")
        self.has=(trimmed_cards.first)
        return
      elsif num_trimmed_cards < 1
        warn("NO CARDS to add: #{timmed_cards.map(&:name)}")
        return
      end

      # No need to avoid adding a list that we already have, cuz this is a Set!

      who_card_name = who_card&.name&.downcase
      what_card_name = what_card&.name&.downcase
      where_card_name = where_card&.name&.downcase

      # jj wants to intersect all the facts in this Set <-- not yet

      possibility = {}
      possibility[:who] = who_card_name if who_card
      possibility[:what] = what_card_name if what_card
      possibility[:where] = where_card_name if where_card # FIXME, use the cards ?!

      #possibility_size = num_trimmed_cards < 3 ? "PARTIAL" : "FULL"
      # warn("ADDING a #{possibility_size} possibility to #{name}: #{possibility.inspect}")
      @has_at_least_one_of << possibility
    end

    # does_not_have # the card
    def does_not_have=(card)
      got = @has & [card]
      if got.empty?
        @does_not_have << card
      else
        warn("Unable to mark card(#{card.name}) as NOT belonging to #{name}; #{got}")
      end
    end

    def has=(card)
      got = @does_not_have & [card]
      if got.empty?
        @has << card
      else
        warn("Unable to assign card(#{card.name}) to #{name}; #{got}")
      end
    end

    def to_s
      @name
    end

    def to_sym
      to_s.to_sym
    end
  end
end
