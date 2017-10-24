#!/usr/bin/env ruby

# Logic:
# mark what you SEE (cuz the board shows it, you have it, or someone shows you)
# mark what you know the DON't HAVE (based on when they can't answer a question)
# make deductions (when possible) based on those facts PLUS the fact that everyone has 3 cards!

module Clue
  class Player
    attr_reader :name, :does_not_know, :knows
    def initialize(name)
      @name = name
      @does_not_know = []
      @knows = []
      @knows_at_least_one_of = []
    end

    def knows_at_least_one_of=(who, what, where)
      #if [who, what, where].any? {|c| @knows.include?(c)}
      @knows_at_least_one_of << {who: who, what: what, where: where}
    end

    def does_not_know=(card)
     @does_not_know << card
    end

    def knows=(card)
     @knows << card
    end

    def to_s
      @name
    end

    def to_sym
      to_s.to_sym
    end
  end

  class Card
    attr_reader :type, :name
    def initialize(type, name)
      @type = type
      @name = name
    end

    def to_s
      @name
    end

    def to_sym
      to_s.to_sym
    end
  end

  class Solver
    THE_BOARD = "the board".freeze
    WHO = [:green, :mustard, :peacock, :plum, :scarlet, :white].freeze
    WHAT = [:wrench, :candlestick, :dagger, :pistol, :lead_pipe, :rope].freeze
    WHERE = [:bathroom, :office, :dining_room, :game_room, :garage, :bedroom, :living_room, :kitchen, :courtyard].freeze

    attr_reader :players, :cards, :your_cards, :board_cards, :opponent_names, :cards_per_player, :current_player
    def initialize(your_name, ordered_names=[], cards_per_player=3)
      validate_player_counts(@number_of_players = ordered_names.size)
      @cards_per_player = cards_per_player
      @your_name = your_name
      @opponent_names = ordered_names.reject {|n| @your_name == n }
      setup_players(ordered_names)
      @your_cards = []
      @board_cards = []
      setup_cards 
    end

    def process_query
      who = prompt("Who did #{current_player} ask about", WHO, false)
      what = prompt("What did #{current_player} ask about", WHAT, false)
      where = prompt("Where did #{current_player} ask about", WHERE, false)

      opponent_names - current_player.name
      players_who_do_not_have_these_cards = prompt(
        "which players explicity confirmed they did not have #{who}, #{what}, and #{where}?", opponent_names
      )
      players_who_knew_one_of_these_cards = prompt(
        "which player confirmed they knew at least one of #{who}, #{what}, and #{where}?", opponent_names, false
      )
      @players.each do |player|
        if players_who_knew_one_of_these_cards.include?(player.name)
          player.knows_at_least_one_of=(who, what, where)
        end

        if players_who_do_not_have_these_cards.include?(player.name)
          player.does_not_know=(who)
          player.does_not_know=(what)
          player.does_not_know=(where)
        end
      end
    end

    def call
      board_cards=(prompt("Is this the %s card showing on the board", card_names))

      your_cards=(prompt("Do you have the %s card", card_names))

      uncertain = true
      next_player = @players.first
      @turn = 0
      while uncertain && @current_player = next_player
        process_query
        uncertain = who.size > 1 || what.size > 1 || where.size > 1
        @turn += 1
        next_player = @players[@turn % @number_of_players]
      end
      "Out of a total of #{total_cards} cards, it was #{who.sample} in the #{where.sample} with the #{what.sample}"
    end

    def who
      possible = @who_cards.select {|c| board_cards.include?(c) }
      possible = possible.reject {|c| your_cards.include?(c) }
      possible = possible.reject {|c| revealed_cards.include?(c) }
      return possible
    end

    def what
      possible = @what_cards.reject {|c| board_cards.include?(c) }
      possible = possible.reject {|c| your_cards.include?(c) }
      possible = possible.reject {|c| revealed_cards.include?(c) }
      return possible
    end

    def where
      possible = @where_cards.select {|c| board_cards.include?(c) }
      possible = possible.reject {|c| your_cards.include?(c) }
      possible = possible.reject {|c| revealed_cards.include?(c) }
      return possible
    end

    def board_cards=(_card_names)
      @board_cards = @cards.select {|c| _card_names.include?(c.name) }
    end

    def your_cards=(_card_names)
      @your_cards = @cards.select {|c| _card_names.include?(c.name) }
    end

    def card_names
      cards.map(&:name)
    end

    def cards
      @who_cards + @what_cards + @where_cards
    end

    protected

    def prompt(message,options=[], many=true, sigil="?")
      many ? many_prompt(message, options, sigil) : single_prompt(message, options, sigil)
    end

    def many_prompt(message, options=[], sigil="?")
      all = []
      options.each do |option|
        query = prompt % option
        print "#{query}? [Y|N] "
        got = gets.chomp
        puts
        (got =~ /Y|y/) ? all.append(option) : true
      end
      return all
    end

    def single_prompt(message, options=[], sigil="?")
      print "#{prompt} #{options.inspect}? "
      got = gets.chomp.to_sym
      puts
      
      return got
    end

    def setup_players(player_names)
      @players = player_names.map {|n| Player.new(n) }
    end

    def setup_cards
      @who_cards   = WHO.map   {|who|   Card.new(:who, who) }
      @what_cards  = WHAT.map  {|what|  Card.new(:what, what) }
      @where_cards = WHERE.map {|where| Card.new(:where, where) }
    end

    def validate_player_counts(count)
      if count < 3
        fail("must have at least 3 players")
      end
      if count > 6
        fail("must have at most 6 players")
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  cs = Clue::Solver.new
  puts cs.call
  puts "done."
end
