use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;

diag("No strategy");
$game = Illuminated::Game->standard_test();
diag("Log file is: " . $game->log_name);


my $p1 = $game->players->[0];
my $p2 = $game->players->[1];

diag("Palading gets close to iota");
$game->configure_scenario( [6, 6], [], ['C iota', 'quit'] );
$game->run;
is($game->get_distance($p1, $game->foes->[6]), 'close', $game->foes->[6]->name . " is close from " . $p1->name);
is($game->get_distance($p2, $game->foes->[6]), 'near', $game->foes->[6]->name . " is near from " . $p2->name);

diag("Templar gets away from csi");
diag("Enemies turn: wasted actiond point");
$game->configure_scenario( [6], [0], ['F csi', 'quit'] );
$game->run;
is($game->get_distance($p1, $game->foes->[7]), 'near', $game->foes->[7]->name . " is near from " . $p1->name);
is($game->get_distance($p2, $game->foes->[7]), 'far', $game->foes->[7]->name . " is far from " . $p2->name);

diag("Paladin disangages from iota with consequences");
diag("Iota reaction: go far from Paladin");
$game->configure_scenario( [4, 4, 4, 3], [0], ['D', 'quit'] );
$game->run;
is($game->get_distance($p1, $game->foes->[6]), 'far', $game->foes->[6]->name . " is far from " . $p1->name);
is($game->get_distance($p2, $game->foes->[6]), 'near', $game->foes->[6]->name . " is near from " . $p2->name);

diag("Templar get close to epsilon with consequences");
diag("Epsilon reaction: harm Templar");
diag("Enemies turn: wasted actiond point");
$game->configure_scenario( [4, 3], [0], ['C epsilon', 'S', 'quit'] );
$game->run;
is($game->get_distance($p1, $game->foes->[3]), 'far', $game->foes->[3]->name . " is far from " . $p1->name);
is($game->get_distance($p2, $game->foes->[3]), 'near', $game->foes->[3]->name . " is near from " . $p2->name);
is($p2->health, 9, "Templar health is now 9");

diag("Paladin tries to fly away from all. Outcome is success with consequences");
diag("Near enemies: delta, csi, pi");
diag("Paladin gets away from delta, fail with csi and pi that raise aegis");
$game->configure_scenario( [3, 3, 6, 1, 1], [0], ['F _all', 'quit'] );
$game->run;
is($game->get_distance($p1, $game->foes->[4]), 'far', $game->foes->[4]->name . " is far from " . $p1->name);
is($game->get_distance($p1, $game->foes->[7]), 'near', $game->foes->[7]->name . " is near from " . $p1->name);
is($game->get_distance($p1, $game->foes->[8]), 'near', $game->foes->[8]->name . " is near from " . $p1->name);
is($game->foes->[7]->has_status('parry'), 1, $game->foes->[7] . " has parry status");
is($game->foes->[8]->has_status('parry'), 1, $game->foes->[7] . " has parry status");

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");



done_testing();
