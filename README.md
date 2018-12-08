# Attack_ship_strat_dev
Scripts and notes for developing strats on attack ship

Contains:
* "Flip-flop" action block, which can be imported into the setup editor to replace 0415. This has simply duplicated the all important loop so that we can easily tell when the action script has run.
* "heart-o-meter" for the right skedar, which tracks the time between 'updates'. Each update, the skedar's position will definitely update. Whether or not the script runs is a little fickle.. but I've used the flip flop action block to check, and the skedar is running it's action block every update when we are far back in the door.
