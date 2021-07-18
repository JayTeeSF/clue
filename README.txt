# play a game, tell us your player's name, followed by the ordered line-up of all the players' names
./bin/clue "Me" "player-1" "Me" "player-3" "player-4"

# option 2: feed sample game into program:
cat data/sample_game_1.txt | ./bin/clue "Me" "player-1" "Me" "player-3" "player-4"

# run a spec to test the output of a sample game (store data in ./data/sample_game_<N>.txt):
# specify the game number <N> followed by the expected_output
> ./spec/sample_game # the default <N> value is 1; the default expected_output is shown on the next line:
OK: "It was Peacock in the courtyard with the lead_pipe"

> ./spec/sample_game 1 "wrong output"
NOK: "It was Peacock in the courtyard with the lead_pipe" != "wrong output"

> ./spec/sample_game 1 "It was Peacock in the courtyard with the lead_pipe"
OK: "It was Peacock in the courtyard with the lead_pipe"
