# Logic:
# mark what you SEE (cuz the board shows it, you have it, or someone shows you)
# mark what you know the DON't HAVE (based on when they can't answer a question)
# make deductions (when possible) based on those facts PLUS the fact that everyone has 3 cards!

require 'set'
require_relative "player"
require_relative "card" # TBD: should card simply be a concommitant of Player ?!
require_relative "freq"

module Clue
  class Solver
    THE_BOARD = "the board".freeze
    WHO = [:green, :mustard, :peacock, :plum, :scarlet, :white].freeze
    WHAT = [:wrench, :candlestick, :dagger, :pistol, :lead_pipe, :rope].freeze
    WHERE = [:bathroom, :office, :dining_room, :game_room, :garage, :bedroom, :living_room, :kitchen, :courtyard].freeze

    attr_reader :players, :cards, :your_cards, :board_cards, :cards_per_player, :current_player
    def initialize(your_name, ordered_names=[], cards_per_player=nil)
      @your_name = your_name
      help("missing your_name") if blank?(your_name)
      warn("YourName: #{your_name.inspect}")
      @number_of_players = ordered_names.size
      validate_player_counts(@number_of_players)

      #@opponent_names = ordered_names.reject {|n| @your_name == n }
      #warn("Opponents: #{@opponent_names.inspect}")

      setup_players(ordered_names)
      @current_player = @players.first
      @your_cards = nil
      @board_cards = nil
      setup_cards
      @cards_per_player = cards_per_player || (total_cards / @number_of_players)
    end

    def play_a_turn
      name_of_player_who_has_one_of_these_cards = nil
      if your_the_current_player?
        # add some info about what players *may* have, but I'm uncertain about... (i.e. probability)

        # add info to each user: their do_not_have as well as their has_one_of... lists...
        # tbd: can we deduce what they must have?
        # tbd: store data in knowledge-base (using either propositional logic or (if nec. first-order logic) in Conjunctive Normal Form: conjunction of disjunctive clauses), and have knowledge-base solve for new propositions
        puts "\nYour turn to figure-out what's in the envelope. You have:\n\t#{current_player.has.map(&:name)}\nThe board shows:\n\t#{board_cards.map(&:name)}\nOther players have shown you:\n\t#{cards_revealed_by_players.inspect}\nAnd you're looking for the:\n\t(#{who.size})who(s): #{who.map(&:name)}, \n\t(#{what.size})what(s): #{what.map(&:name)}, \n\t(#{where.size})where(s): #{where.map(&:name)}\n"
      end

      who_asked = prompt("Who did #{current_player} ask about", WHO, false)
      what_asked = prompt("What did #{current_player} ask about", WHAT, false)
      where_asked = prompt("Where did #{current_player} ask about", WHERE, false)

      names_of_players_who_do_not_have_these_cards = prompt(
        "Did your opponent '%s' explicity confirm (s)he does not have any of these cards: #{who_asked}, #{what_asked}, or #{where_asked}", opponent_names
      )

      if your_the_current_player?
        player_who_showed_you_a_card = prompt("Which opponent showed you a card", opponent_names, false) # at most one player!
        #warn("DEBUG: player_who_showed_you_a_card: #{player_who_showed_you_a_card.inspect} <-- if we get empty then we need to NOT ask about card_player_showed_you...")
        # "" not null

        # where do I keep track of which cards another player has shown me?!
        # Or the probabilities of what I suspect other players have:
        player_who_showed_you_a_card = nil if blank?(player_who_showed_you_a_card)
        if player_who_showed_you_a_card
          # player_who_showed_you_a_card = player_who_showed_you_a_card.to_s
          card_player_showed_you = prompt("Which card did #{player_who_showed_you_a_card} show you", ((card_names - board_cards.map(&:name)) - your_cards.map(&:name)), false)
          card_player_showed_you = nil if blank?(card_player_showed_you)
          #warn("DEBUG: SHOWN: #{card_player_showed_you.inspect} by: #{player_who_showed_you_a_card.inspect}")
        end
      else
          # "Which opponent confirmed (s)he has at least one of #{who_asked}, #{what_asked}, and #{where_asked}", opponent_names + ["nobody".to_sym], false # there can only be one, but it could have been you!
        name_of_player_who_has_one_of_these_cards = prompt(
          "Which opponent confirmed (s)he has at least one of #{who_asked}, #{what_asked}, and #{where_asked}", opponent_names + ["press <return>/<enter> for you OR nobody".to_sym], false
        )
        name_of_player_who_has_one_of_these_cards = nil if blank?(name_of_player_who_has_one_of_these_cards)
      end

      opponents_of(current_player).each do |player|
        if name_of_player_who_has_one_of_these_cards&.downcase == player.name.downcase #name_of_player... could be "nobody"
          player.has_at_least_one_of(card_named(who_asked), card_named(what_asked), card_named(where_asked))
        end

        if your_the_current_player?
          #   handle case where you were actually shown a specific card, by a single player...
          if card_player_showed_you && player_who_showed_you_a_card.downcase == player.name.downcase
            #warn("DEBUG: ADDING CARD #{card_player_showed_you.inspect} I WAS SHOWN by #{player_who_showed_you_a_card.inspect}; player.name: #{player.name.inspect}")
            player.has=(card_named(card_player_showed_you))
            # else #warn("DEBUG: UNABLE TO ADD CARD #{card_player_showed_you.inspect} I WAS SHOWN by #{player_who_showed_you_a_card.inspect}; player.name: #{player.name.inspect}")
          end
        else
          if names_of_players_who_do_not_have_these_cards.map(&:downcase).include?(player.name.downcase)
            player.does_not_have=(card_named(who_asked))
            player.does_not_have=(card_named(what_asked))
            player.does_not_have=(card_named(where_asked))
          end
        end
      end
    end

    def solve
      self.board_cards=(prompt("Is this the %s card showing on the board", card_names))
      #warn("board_cards: #{board_cards.map(&:name)}")
      puts

      self.your_cards=(prompt("Do you have the %s card", (card_names - board_cards.map(&:name))))
      # warn("your_cards: #{your_cards.inspect}")
      puts

      #freq = Clue::Freq.new(["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"])
      #puts freq.map_frequencies.inspect

      uncertain = true
      next_player = @current_player
      @turn = 0
      while uncertain && @current_player = next_player
        puts "\nStarting the game...\n" if @turn == 0
        play_a_turn
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

    def revealed_cards
      # loop over each opponent player object and look at the cards we KNOW they have..
      _cards = Set.new([])
      opponent_players.each do |player|
        #_cards += player.has 
        player.has.each { |c| _cards << c }
      end
      #warn("DEBUG: revealed cards: #{_cards.map(&:name)}") # has should include actual cards, not simply names
      _cards
    end

    def cards_revealed_by_players
      opponent_players.reduce({}) {|m, p| m[p.name] = p.has.map(&:name); m}
    end

    def certain_of(possible=[])
      certain = Set.new(possible)
      msgs = []
      msgs << "certain_of(#{certain.map(&:name)}): "
      @players.each do |player|
        certain = certain & player.does_not_have
        msgs << "player #{player.name} doesn't have: #{player.does_not_have.map(&:name)} => #{certain.map(&:name)}"
        break if certain.empty?
      end
      #warn(%Q|DEBUG: #{msgs.join("\n\t")} => R: #{certain.map(&:name)}|)
      certain 
    end

    def who
      possible = @who_cards.reject {|c| board_cards.include?(c) } # make this a reject
      possible = possible.reject {|c| your_cards.include?(c) } # 
      possible = possible.reject {|c| revealed_cards.include?(c) } # what about cards that we were shown

      # if everybody has some cards in their does_not_have list(s) then it's certain (not uncertain) what the answer is
      # cards nobody has (cuz they all ) based on analyzing all the questions and what people didn't know (don't get confused by the person who gives AN answer but has multiple answers that we don't know about...) loop over @players.reduce([]) {|m, p| m << p.does_not_know }
      # do a set manipulation to get the overlap intersection!!!
      # warn("DEBUG: who-possible: #{possible.inspect}")
      got = certain_of(possible)
      got.empty? ? possible : got
    end

    def what
      possible = @what_cards.reject {|c| board_cards.include?(c) }
      possible = possible.reject {|c| your_cards.include?(c) }
      possible = possible.reject {|c| revealed_cards.include?(c) }

      got = certain_of(possible)
      got.empty? ? possible : got
    end

    def where
      possible = @where_cards.reject {|c| board_cards.include?(c) } # should this be a reject ?!
      possible = possible.reject {|c| your_cards.include?(c) }
      possible = possible.reject {|c| revealed_cards.include?(c) }

      got = certain_of(possible)
      got.empty? ? possible : got
    end

    def board_cards=(_card_names)
      @board_cards ||= cards.select {|c| _card_names.map(&:downcase).include?(c.name.downcase) }
    end

    def opponent_names
      opponents_of(current_player, your_player).map(&:name)
    end

    def opponent_players
      @opponent_players ||= @players.reject {|p| p.name == @your_name }
    end

    def your_player
      @your_player ||= @players.detect {|p| p.name == @your_name }
    end

    def opponents_of(some_player, except=nil)
      starting_index = @players.index(some_player) + 1
      ending_index = starting_index + @number_of_players - 1 - 1 # don't include "some_player"

      opps = (starting_index..ending_index).map { |player_idx| @players[player_idx % @number_of_players] } - [except]
      #warn("DEBUG: opponents_of(#{some_player&.name}, #{except&.name}) => #{opps.map(&:name)}")
      opps
    end

    def your_the_current_player?
      current_player.name == @your_name
    end
    
    def your_cards=(_card_names)
      unless @your_cards
        @your_cards = cards.select {|c| _card_names.map(&:downcase).include?(c.name.downcase) }
        # set your player.has to be these cards...
        @your_cards.each {|c| your_player.has=(c) }
        (cards - @your_cards).each {|c| your_player.does_not_have=(c) }
      end
      @your_cards
    end

    def card_names
      cards.map(&:name)
    end

    def card_named(card_name)
      cards.detect {|c| c.name.downcase == card_name.downcase }
    end

    def cards
      @cards ||= @who_cards + @what_cards + @where_cards
    end

    def prompt(message,options=[], many=true, sigil="?")
      many ? many_prompt(message, options, sigil) : single_prompt(message, options, sigil)
    end

    def blank?(str)
      str.nil? || str == "" || str == " "
    end

    protected

    def many_prompt(message, options=[], sigil="?")
      all = []
      options.each do |option|
        query = message % option
        print "#{query}? [Y|N] "
        got = STDIN.gets.chomp
        puts
        (got =~ /Y|y/) ? all.append(option) : nil
      end
      return all&.map(&:to_s) # stringified
    end

    def single_prompt(message, options=[], sigil="?")
      print "#{message} #{options.inspect}? "
      response = STDIN.gets.chomp
      got = response&.to_sym
      puts

      return got&.to_s # stringified
    end

    def setup_players(ordered_player_names)
      @players = ordered_player_names.map {|n| Player.new(n) }
    end

    def setup_cards
      @who_cards   = WHO.map   {|who|   Card.new(:who, who) }
      @what_cards  = WHAT.map  {|what|  Card.new(:what, what) }
      @where_cards = WHERE.map {|where| Card.new(:where, where) }
    end

    def ordered_player_names
      @ordered_player_names ||= @players.map(&:name)
    end

    def help(msg)
      help_msg = <<-EOF

        #{msg}

        Usage: #{$PROGRAM_NAME} <your_name> <first_player*> <second_player*> ...<nth_player*>
        *Note: Be sure to repeat <your_name> in the order you show-up in the line-up.

        e.g.: #{$PROGRAM_NAME} "Me" "player-1" "Me" "player-3" "player-4"
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
end
