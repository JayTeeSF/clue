# Logic:
# mark what you SEE (cuz the board shows it, you have it, or someone shows you)
# mark what you know the DON't HAVE (based on when they can't answer a question)
# make deductions (when possible) based on those facts PLUS the fact that everyone has <cards_per_player> cards

require 'set'
require_relative "player"
require_relative "card" # TBD: should card simply be a concommitant of Player ?!
require_relative "freq"
require 'securerandom'

module Clue
  class Solver
    THE_BOARD = "the board".freeze
    WHO = [:green, :mustard, :peacock, :plum, :scarlet, :white].freeze
    WHAT = [:candlestick, :dagger, :pistol, :lead_pipe, :rope, :wrench].freeze
    #WHAT = [:wrench, :candlestick, :dagger, :pistol, :lead_pipe, :rope].freeze

    WHERE = [:bathroom, :bedroom, :courtyard, :dining_room, :game_room, :garage, :kitchen, :living_room, :office].freeze
    #WHERE = [:bathroom, :office, :dining_room, :game_room, :garage, :bedroom, :living_room, :kitchen, :courtyard].freeze


    def self.find_player_by_name(player_name, players)
      players.find {|p| p.name&.downcase == player_name&.downcase }
    end

    def log(log_line)
      return unless @output_file
      File.open(@output_file, "a+") {|log| log.puts(log_line) }
    end

    attr_reader :players, :cards, :your_cards, :board_cards, :cards_per_player, :current_player
    def initialize(your_name, ordered_names=[], cards_per_player:nil, output_file:nil, input_file:nil)
      if @output_file = output_file || "#{__dir__}/../../tmp/sample_game_#{SecureRandom.uuid}"
        warn("Logging output for this session to #{@output_file} ...consider moving to 'data/sample_game_<N>'")
      end
      @input_file = input_file || STDIN
      @your_name = your_name
      help("missing your_name") if blank?(your_name)
      @number_of_players = ordered_names.size
      validate_player_counts(@number_of_players)

      setup_cards
      setup_players(ordered_names)
      @current_player = @players.first
      @your_cards = nil
      @board_cards = nil
    end

    def solve
      @cards_per_player = calc_cards_per_player(@number_of_players, expected_board_card_count(@number_of_players))
      @cards_per_player ||= (total_card_count / @number_of_players) # if the other thing returned nil
      # at the moment we're not using this and we should...
      # if we know 2 of someone's card(s), plus the board cards
      # ...we should be able to deduce their 3rd card (maybe)?!

      self.board_cards=(prompt("Is this the %s card showing on the board", card_names, stop_at: @expected_board_card_count))
      #warn("board_cards: #{board_cards.map(&:name)}")
      #unless @expected_board_card_count == board_cards.size
      #  warn("WRONG NUMBER of BOARD CARDS, got: %d, expected: %d" % [board_cards.size, @expected_board_card_count])
      #end
      warn

      self.your_cards=(prompt("Do you have the %s card", (card_names - board_cards.map(&:name)), stop_at: @cards_per_player))
      # warn("your_cards: #{your_cards.inspect}")
      #unless @cards_per_player == your_cards.size
      #  warn("WRONG NUMBER of CARDS for YOU, got: %d, expected: %d" % [your_cards.size, @cards_per_player])
      #end
      warn

      # remove board_cards & your_cards from each player's hand
      opponent_players.each {|player|
        impossible_cards.each {|c| player.does_not_have=(c) }
      }

      #freq = Clue::Freq.new(["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"])
      #puts freq.map_frequencies.inspect

      # the solver becomes "certain" at the point that it has exactly _one_ who, _one_ what, and _one_ where...
      uncertain = true

      next_player = @current_player
      @turn = 0
      while uncertain && @current_player = next_player
        warn "\nStarting the game...\n" if @turn == 0
        play_a_turn
        uncertain = who.size > 1 || what.size > 1 || where.size > 1
        @turn += 1
        next_player = @players[@turn % @number_of_players]
        if almost_certain = who.size <= 2 && what.size <= 2 && where.size <= 2
          warn "\tAlmost certain on all fronts!!!\n"
        end
      end
      "It was #{who.first.name.capitalize} in the #{where.first} with the #{what.first}"
    end

    def play_a_turn
      name_of_player_who_has_one_of_these_cards = nil
      if your_the_current_player?
        # add some info about what players *may* have, but I'm uncertain about... (i.e. probability)

        # tbd: can we deduce what they must have?
        # use player.has_one_of(s) in comparison with what's been revealed by other players in order to create shorter lists of has_one_of(s)
        # e.g. player-1 has_one_of: who, what, where until we know someone else has that "what", so we make a new fact that says, player-1.has_one_of who, where
        # until we can ultimately narrow it down to a single card ...at which point we move that card to their "has" list!!
        #
        # tbd: store data in knowledge-base (using either propositional logic or (if nec. first-order logic) in Conjunctive Normal Form: conjunction of disjunctive clauses), and have knowledge-base solve for new propositions
        info(:pre)
      end

      who_asked = prompt("Who did #{current_player} ask about", WHO, false, match: true)
      what_asked = prompt("What did #{current_player} ask about", WHAT, false, match: true)
      where_asked = prompt("Where did #{current_player} ask about", WHERE, false, match: true)
      who_card = card_named(who_asked)
      what_card = card_named(what_asked)
      where_card = card_named(where_asked)

      names_of_players_who_do_not_have_these_cards = prompt(
        "Did your opponent '%s' explicity confirm (s)he does not have any of these cards: #{who_asked}, #{what_asked}, or #{where_asked}", opponent_names
      )

      if your_the_current_player?
        player_who_showed_you_a_card = prompt("Which opponent showed you a card", opponent_names, false) # at most one player!
        #warn("DEBUG: player_who_showed_you_a_card: #{player_who_showed_you_a_card.inspect} <-- if we get empty then we need to NOT ask about card_player_showed_you...")

        player_who_showed_you_a_card = nil if blank?(player_who_showed_you_a_card)
        if player_who_showed_you_a_card
          card_player_showed_you = prompt("Which card did #{player_who_showed_you_a_card} show you", ((card_names - board_cards.map(&:name)) - your_cards.map(&:name)), false)
          card_player_showed_you = nil if blank?(card_player_showed_you)
          #warn("DEBUG: SHOWN: #{card_player_showed_you.inspect} by: #{player_who_showed_you_a_card.inspect}")
        end
      else
        name_of_player_who_has_one_of_these_cards = prompt(
          "Which opponent confirmed (s)he has at least one of #{who_asked}, #{what_asked}, and #{where_asked}", opponent_names + ["press <return>/<enter> for you OR nobody".to_sym], false
        )
        name_of_player_who_has_one_of_these_cards = nil if blank?(name_of_player_who_has_one_of_these_cards)
      end

      opponents_of(current_player).each do |player| # no need to add ME to the list: we already stored all of the cards ME doesn't have
        if names_of_players_who_do_not_have_these_cards.map(&:downcase).include?(player.name.downcase)

          player.does_not_have=(who_card)
          player.does_not_have=(what_card)
          player.does_not_have=(where_card)
        end

        if your_the_current_player?
          #   handle case where you were actually shown a specific card, by a single player...
          if card_player_showed_you && player_who_showed_you_a_card.downcase == player.name.downcase
            player.has=(card_named(card_player_showed_you))
          end
        end
      end

      update_player_who_showed_a_card(name_of_player_who_has_one_of_these_cards, who_card, what_card, where_card)

      # update all the facts...
      opponent_players.each do |player| # my opponents
        update_what_player_does_not_have(player)
        # augment existing knowledge first ...and again afterwards, in case we learned something new ?!

        # update our guesses as to what this player has based on the latest evidence:
        # TODO 1: possibilities = player.possibilities
        # TODO 2: player.clear_possibilities
        # TODO 3: re-add each possibility
        re_evaluate_possibilities_for(player)
      end

      if your_the_current_player?
        info(:post)
      end
    end

    def update_player_who_showed_a_card(name_of_player, who_card, what_card, where_card)
      #name_of_player... could be "nobody"
      player = self.class.find_player_by_name(name_of_player&.downcase, opponent_players)
      unless player
        warn("Unable to find player named: #{name_of_player.inspect} (in players: #{opponent_players.inspect}), who showed a card to our opponent!")
        return 
      end

      update_what_player_does_not_have(player)
      player.has_at_least_one_of(who_card, what_card, where_card)
    end

    def update_what_player_does_not_have(player)
      other_players_cards = revealed_cards(except_from_player: player)
      (impossible_cards + other_players_cards.to_a).each {|c| player.does_not_have=(c) }
    end

    def re_evaluate_possibilities_for(player)
      possibilities = player.possibilities.dup # dup necessary, or the next line will clear our reference too!
      player.clear_possibilities # <-- I don't like that we ultimately lose the history of these possibilities!
      possibilities.each do |possibility| # set
        who_card = card_named(possibility[:who])
        what_card = card_named(possibility[:what])
        where_card = card_named(possibility[:where])

        # re-add it
        player.has_at_least_one_of(who_card, what_card, where_card)
      end
    end

    def total_card_count
      cards.size
    end

    # list
    def revealed_cards(except_from_player: nil)
      # loop over each opponent player object and look at the cards we KNOW they have..
      _cards = Set.new([])
      player_list = except_from_player ? opponents_of(except_from_player, your_player) : opponent_players
      player_list.each do |player|
        player.has.each { |c| _cards << c }
      end
      #warn("DEBUG: revealed cards: #{_cards.map(&:name)}") # has should include actual cards, not simply names
      _cards
    end

    # data-structure -- debug output
    def cards_revealed_by_players
      opponent_players.reduce({}) {|m, p| m[p.name] = p.has.map(&:name); m}
    end

    # data-structure -- debug output
    def player_possibilities
      list = opponent_players.reduce([]) { |ary, p|
        ary << "#{p.name}:\n\t\t#{p.possibilities_to_s}"
        ary
      }
      list.join("\n\t")
    end

    # if everybody has some cards in their does_not_have list(s) then it's certain (not uncertain) what the answer is
    # assuming that card was _also_ in the possible list (i.e. no user has the board cards, but board cards are already rejected from the possible list)
    #
    # don't get confused by the person who gives AN answer but has multiple answers that we don't know about...
    def certain_of(possible=[])
      certain = Set.new(possible)
      msgs = []
      #msgs << "certain_of(#{certain.map(&:name)}): "
      @players.each do |player|
        # use a set operation (intersection) to get the overlap:
        certain = certain & player.does_not_have
        #msgs << "player #{player.name} doesn't have: #{player.does_not_have.map(&:name)} => #{certain.map(&:name)}"
        break if certain.empty?
      end
      # already filtered the board cards, so they aren't even possible!
      #warn(%Q|DEBUG: #{msgs.join("\n\t")} => R: #{certain.map(&:name)}|)
      certain 
    end

    def impossible_cards
      (board_cards||[]) + (your_cards||[]) # + revealed_cards
    end

    def who # from perspective of the envelope
      possible = @who_cards.reject {|c| impossible_cards.include?(c) }
      possible = possible.reject {|c| revealed_cards.include?(c) }

      got = certain_of(possible)
      got.empty? ? possible : got
    end

    def what # from perspective of the envelope
      possible = @what_cards.reject {|c| impossible_cards.include?(c) }
      possible = possible.reject {|c| revealed_cards.include?(c) }

      got = certain_of(possible)
      got.empty? ? possible : got
    end

    def where # from perspective of the envelope
      possible = @where_cards.reject {|c| impossible_cards.include?(c) }
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
      @your_player ||= self.class.find_player_by_name(@your_name, @players)
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
        # set your_player#has:
        @your_cards.each {|c| your_player.has=(c) }

        # set all the cards your player does not have:
        (cards - @your_cards).each {|c| your_player.does_not_have=(c) }
      end
      @your_cards
    end

    def card_names
      cards.map(&:name)
    end

    def card_named(card_name)
      return unless card_name
      cards.find {|c| c.name.downcase == card_name.downcase }
    end

    def cards
      @cards ||= @who_cards + @what_cards + @where_cards
    end

    def info(mode=:pre)
      prefix = case mode
               when :pre
                 "\nYour turn to figure-out what's in the envelope. You have:"
               when :post
                 "\nAfter your turn you have:"
               else
                 "\nYou have:"
               end
      warn "#{prefix}\n\t#{current_player.has&.map(&:name)}\nThe board shows:\n\t#{board_cards&.map(&:name)}\nOther players have shown you:\n\t#{cards_revealed_by_players.inspect}\nPlus they have one or more of the following:\n\t#{player_possibilities}\nAnd you're looking for the:\n\t(#{who.size})who(s): #{who&.map(&:name)}, \n\t(#{what.size})what(s): #{what&.map(&:name)}, \n\t(#{where.size})where(s): #{where&.map(&:name)}\n"
    end

    def prompt(message, options=[], many=true, sigil="?", match: false, stop_at: nil)
      many ? many_prompt(message, options, sigil, match: match, stop_at: stop_at) : single_prompt(message, options, sigil, match: match)
    end

    def blank?(str)
      # str.nil? || str == "" || str == " "
      [nil, "", " "].include?(str)
    end

    protected

    def print_warn(msg)
      STDERR.print(msg)
    end

    def many_prompt(message, options=[], sigil="?", match: false, stop_at: nil)
      all = []
      options.each do |option|
        if stop_at && all.size >= stop_at
          break
        end
        query = message % option
        prompt = "#{query}? [Y|N] "
        print_warn prompt
        got = @input_file.gets&.chomp
        fail("received a nil: #{got.inspect}") if got.nil?
        warn
        got && got.gsub!(/\#.*$/, '')
        if got&.downcase == 'i'
          info()
          redo # repeat this loop
        end

        if match
          unless options.map {|o| o.to_s.downcase }.include?(got&.downcase)
            warn("Invalid input, please try again...")
            redo # repeat this loop
          end
        end

        #if ((got || "") =~ /^\s*(Y|y)/)
        if (got =~ /^\s*(Y|y)/)
          log("Y # #{prompt}")
          all.append(option)
        else
          log("N # #{prompt}")
          nil
        end
      end
      return all&.map(&:to_s) # stringified
    end

    def single_prompt(message, options=[], sigil="?", match: false)
      prompt = "#{message} #{options.inspect}? "
      print_warn prompt
      response = @input_file.gets&.chomp

      fail("received a nil: #{response.inspect}") if response.nil?
      response && response.gsub!(/\#.*$/, '')
      got = response&.to_sym
      warn
      if response&.downcase == 'i'
        info()
        return single_prompt(message, options, sigil)
      end

      if match
        unless options.map {|o| o.to_s.downcase }.include?(got&.to_s&.downcase)
          warn("Invalid input, please try again...")
          return single_prompt(message, options, sigil)
        end
      end
      
      log("#{got} # #{prompt}")
      return got&.to_s # stringified
    end

    def setup_players(ordered_player_names)
      @players = ordered_player_names.map {|n| Player.new(n, cards.map {|c| c.name.length}.max) }
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

    CLASSIC_FACE_UP_CARDS_PER_PLAYER_CT = {
      3 => 0,
      4 => 2,
      5 => 3,
      6 => 0,
    }
    FACE_UP_CARDS_PER_PLAYER_CT = {
      3 => 6,
      4 => 6,
      5 => 3,
      6 => 6,
    }

    def expected_board_card_count(num_players)
      @expected_board_card_count ||= FACE_UP_CARDS_PER_PLAYER_CT[num_players]
    end

    def calc_cards_per_player(num_players, board_card_count)
      (total_card_count - board_card_count) / num_players
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
