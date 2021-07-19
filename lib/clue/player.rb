require 'set'
# TBD: consider adding arrays of Card(s) to each Player instance
# require_relative "card"

module Clue
  class Player
    attr_reader :name, :does_not_have, :has
    def initialize(name)
      @name = name.to_s
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

      guess = {}
      guess[:who] = who_card_name if who_card
      guess[:what] = what_card_name if what_card
      guess[:where] = where_card_name if where_card # FIXME, use the cards ?!

      warn("ADDING a partial guess to #{name}: #{guess.inspect}") if num_trimmed_cards < 3
      @has_at_least_one_of << guess

      # crash this list against both: @has & @does_not_have
      #if [who_card_name, what_card_name, where_card_name].any? { |c|
      #  @has.map(&:name).include?(c)
      #}
      #  warn("DEBUG: update #{name}'s list of has_at_least_one_of to NOT include: ???")
      #end
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
