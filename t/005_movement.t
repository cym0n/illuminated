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
$game->configure_scenario( [4, 4, 4, 3], [], ['D', 'quit'] );
$game->run;
is($game->get_distance($p1, $game->foes->[6]), 'far', $game->foes->[6]->name . " is far from " . $p1->name);
is($game->get_distance($p2, $game->foes->[6]), 'near', $game->foes->[6]->name . " is near from " . $p2->name);

diag("Templar get close to epsilon with consequences");
diag("Epsilon reaction: harm Templar");
diag("Enemies turn: wasted actiond point");
$game->configure_scenario( [4, 3], [0], ['C epsilon', 'quit'] );
$game->run;
is($game->get_distance($p1, $game->foes->[3]), 'far', $game->foes->[3]->name . " is far from " . $p1->name);
is($game->get_distance($p2, $game->foes->[3]), 'near', $game->foes->[3]->name . " is near from " . $p2->name);
is($p2->health, 9, "Templar health is now 9");



done_testing();
