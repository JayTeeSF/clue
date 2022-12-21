# play a game, tell us your player's name, followed by the ordered line-up of all the players' names
./bin/clue "Me" "player-1" "Me" "player-3" "player-4"

# option 2: feed sample game into program:
cat data/sample_game_1.txt | ./bin/clue "Me" "player-1" "Me" "player-3" "player-4"

# run a spec to test the output of a sample game (store data in ./data/sample_game_<N>.txt):
# specify the game number <N> followed by the expected_output
> ./spec/sample_game # the default <N> value is 1; the default expected_output is shown on the next line:
testing src_code...
OK: "It was Peacock in the courtyard with the dagger"

# hide warning message telling you the testing mode w/  2>/dev/null
> ./spec/sample_game
OK: "It was Peacock in the courtyard with the dagger"

> ./spec/sample_game 1 "wrong output"  2>/dev/null
NOK: "It was Peacock in the courtyard with the dagger" != "wrong output"

> ./spec/sample_game 1 "It was Peacock in the courtyard with the dagger"
testing src_code...
OK: "It was Peacock in the courtyard with the dagger"

> ./spec/sample_game 1 "It was Peacock in the courtyard with the dagger" cmd_line
testing cmd_line...
OK: "It was Peacock in the courtyard with the dagger"

> ./spec/sample_game src_code
testing src_code...
OK: "It was Peacock in the courtyard with the dagger"

> ./spec/sample_game cmd_line
testing cmd_line...
OK: "It was Peacock in the courtyard with the dagger"

Sample Game 1 (secret) setup:
Board:
  Green, Mustard, Candlestick, Bathroom, Office, Dining Room
Envelope:
  Peacock, Lead Pipe, Courtyard
Player-1:
  Plum, Wrench, Scarlet
Player-2(Me):
  Dagger, Pistol, Living Room
Player-3:
  Rope, Game Room, Kitchen
Player-4:
  Garage, Bedroom, White

Turn(s):
1: plum, wrench, kitchen
 no, no, player-3

2: scarlet, pistol, living-room
 y, y, no, player-1, scarlet

3: peacock, rope, kitchen
 y, y, <nobody>

4: White, Rope, Garage
 y, n, player-3


5: scarlet, rope, game-room
 n, n, player-3

6: white, pistol, living_room
 yes, yes, no, player-4

7: plum, rope, game-room
 n, y, player-1

8: peacock, lead-pipe, bedroom
 n, y, y

9: scarlet, wrench, game_room
 y, y, n (player-3)
