#!/usr/bin/env ruby

# Logic:
# mark what you SEE (cuz the board shows it, you have it, or someone shows you)
# mark what you know the DON't HAVE (based on when they can't answer a question)
# make deductions (when possible) based on those facts PLUS the fact that everyone has 3 cards!

module Clue
  class Player
    attr_reader :name, :does_not_have, :has
    def initialize(name)
      @name = name
      @does_not_have = []
      @has = []
      @has_at_least_one_of = []
    end

    def has_at_least_one_of(who_name, what_name, where_name)
      #if [who, what, where].any? {|c| @has.include?(c)}
      @has_at_least_one_of << {who: who_name, what: what_name, where: where_name}
    end

    # does_not_have # the card
    def does_not_have=(card)
      @does_not_have << card
      if got = @has & @does_no_have
        fail("we have and don't have the same card(s): #{got}")
      end
    end

    def has=(card)
      @has << card
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
    def initialize(your_name, ordered_names=[], cards_per_player=nil)
      @your_name = your_name
      help("missing your_name") if blank?(your_name)
      warn("YourName: #{your_name.inspect}")
      @number_of_players = ordered_names.size
      validate_player_counts(@number_of_players)

      @opponent_names = ordered_names.reject {|n| @your_name == n }
      warn("Opponents: #{@opponent_names.inspect}")

      setup_players(ordered_names)
      @current_player = @players.first
      @your_cards = nil
      @board_cards = nil
      setup_cards
      @cards_per_player = cards_per_player || (total_cards / @number_of_players)
    end

    def ordered_player_names
      @ordered_player_names ||= @players.map(&:name)
    end

    def process_query
      if current_player.name == @your_name
        puts "Your turn to figure-out about: who(s): #{who.inspect}, what(s): #{what.inspect}, where(s): #{where.inspect}"
      end

      who_asked = prompt("Who did #{current_player} ask about", WHO, false)
      what_asked = prompt("What did #{current_player} ask about", WHAT, false)
      where_asked = prompt("Where did #{current_player} ask about", WHERE, false)

      #  opponent_names - current_player.name # not storing the results of this statement so why do it ?!
      names_of_players_who_do_not_have_these_cards = prompt(
        "Did your opponent '%s' explicity confirm (s)he does not have any of these cards: #{who_asked}, #{what_asked}, or #{where_asked}", (opponent_names - [current_player.name])
      )
      if current_player.name == @your_name
        player_who_showed_you_a_card = prompt("Did your opponent '%s' show you a card", opponent_names, false) # at most one player!
        card_player_showed_you = prompt("Did #{player_who_showed_you_a_card} show you %s", card_names, false)
      end
      name_of_player_who_has_one_of_these_cards = prompt(
        "Which opponent confirmed (s)he has at least one of #{who_asked}, #{what_asked}, and #{where_asked}", opponent_names + ["nobody".to_sym], false # there can only be one, but it could have been you!
      )
      @players.each do |player|
        # if name_of_player_who_have_one_of_these_cards.include?(player.name) # there can be at most one, but it's still an array from prompt
        if name_of_player_who_have_one_of_these_cards == player.name #name_of_player... could be "nobody"
          player.has_at_least_one_of(who_asked, what_asked, where_asked)
        end

        if current_player.name == @your_name
          #   handle case where you were actually shown a specific card, by a single player...
          if player_who_showed_you_a_card == player.name
            player.has=(card_player_showed_you)
          end
        else
          if names_of_players_who_do_not_have_these_cards.include?(player.name)
            player.does_not_have=(who_asked)
            player.does_not_have=(what_asked)
            player.does_not_have=(where_asked)
          end
        end
      end
    end

    def call
      self.board_cards=(prompt("Is this the %s card showing on the board", card_names))
      warn("board_cards: #{board_cards.inspect}")

      self.your_cards=(prompt("Do you have the %s card", (card_names - board_cards.map(&:name))))
      warn("your_cards: #{your_cards.inspect}")

      #freq = Clue::Freq.new(["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"])
      #puts freq.map_frequencies.inspect

      uncertain = true
      next_player = @players.first
      @turn = 0
      while uncertain && @current_player = next_player
        puts "\nStarting the game...\n" if @turn == 0
        process_query
        uncertain = who.size > 1 || what.size > 1 || where.size > 1
        #    # ...
        @turn += 1
        next_player = @players[@turn % @number_of_players]
      end
      "Out of a total of #{total_cards} cards, it was #{who.sample} in the #{where.sample} with the #{what.sample}"
    end

    def total_cards
      cards.size
    end

    def certain_of(possible=[])
      certain = possible.dup
      @players.each do |player|
        certain = certain & player.does_not_know
        break if certain.blank?
      end
      certain 
    end

    def opponent_players
      @opponent_players ||= @players.reject {|p| p.name == @your_name }
    end

    def revealed_cards
      # loop over each opponent player object and look at the cards we KNOW they have..
      cards = []
      opponent_players.each do |player|
        cards += player.has 
      end
      cards
    end

    def who
      possible = @who_cards.reject {|c| board_cards.include?(c) } # make this a reject
      possible = possible.reject {|c| your_cards.include?(c) } # 
      possible = possible.reject {|c| revealed_cards.include?(c) } # what about cards that we were shown

      # if everybody has some cards in their does_not_have list(s) then it's certain (not uncertain) what the answer is
      # cards nobody has (cuz they all ) based on analyzing all the questions and what people didn't know (don't get confused by the person who gives AN answer but has multiple answers that we don't know about...) loop over @players.reduce([]) {|m, p| m << p.does_not_know }
      # do a set manipulation to get the overlap intersection!!!
      got = certain_of(possible)
      got.empty? ? possible : got
    end

    def what
      possible = @what_cards.reject {|c| board_cards.include?(c) }
      possible = possible.reject {|c| your_cards.include?(c) }
      possible = possible.reject {|c| revealed_cards.include?(c) }

      got = certain_of(possible)
      got.blank? ? possible : got
    end

    def where
      possible = @where_cards.reject {|c| board_cards.include?(c) } # should this be a reject ?!
      possible = possible.reject {|c| your_cards.include?(c) }
      possible = possible.reject {|c| revealed_cards.include?(c) }

      got = certain_of(possible)
      got.blank? ? possible : got
    end

    def board_cards=(_card_names)
      @board_cards ||= cards.select {|c| _card_names.include?(c.name) }
    end

    def your_cards=(_card_names)
      @your_cards ||= cards.select {|c| _card_names.include?(c.name) }
    end

    def card_names
      cards.map(&:name)
    end

    def cards
      @cards ||= @who_cards + @what_cards + @where_cards
    end

    protected

    def blank?(str)
      str.nil? || str == "" || str == " "
    end

    def prompt(message,options=[], many=true, sigil="?")
      many ? many_prompt(message, options, sigil) : single_prompt(message, options, sigil)
    end

    def many_prompt(message, options=[], sigil="?")
      all = []
      options.each do |option|
        query = message % option
        print "#{query}? [Y|N] "
        got = STDIN.gets.chomp
        puts
        (got =~ /Y|y/) ? all.append(option) : nil
      end
      return all
    end

    def single_prompt(message, options=[], sigil="?")
      print "#{message} #{options.inspect}? "
      response = STDIN.gets.chomp
      got = response&.to_sym
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

    def help(msg)
      help_msg = <<-EOF

        #{msg}

        Usage: #{$PROGRAM_NAME} <your_name> <first_player*> <second_player*> ...<nth_player*>
        *Note: Be sure to repeat <your_name> in the order you show-up in the line-up.

        e.g.: #{$PROGRAM_NAME} "Me" "JJ" "Me" "Mama" "Maisha"
      EOF
      fail(help_msg)
    end
    def validate_player_counts(count)
      if count < 3
        help("must have at least 3 players")
      end
      if count > 6
        help("must have at most 6 players")
      end
    end
  end

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

if __FILE__ == $PROGRAM_NAME
  name, *opponents = ARGV
  cs = Clue::Solver.new(name, opponents)
  puts cs.call
  #freq = Clue::Freq.new(["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"])
  #puts freq.map_frequencies.inspect
  #puts "done."
end
