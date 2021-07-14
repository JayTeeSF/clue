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

    def has_at_least_one_of(who_card, what_card, where_card)
      who_name = who_card.name
      # who_card = 
      what_name = what_card.name
      where_name = where_card.name
      # crash this list against both: @has & @does_not_have
      #if [who_name, what_name, where_name].any? { |c|
      #  @has.map(&:name).include?(c)
      #}
      #  warn("DEBUG: update #{name}'s list of has_at_least_one_of to NOT include: ???")
      #end
      @has_at_least_one_of << {who: who_name, what: what_name, where: where_name} # FIXME, use the cards ?!
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
