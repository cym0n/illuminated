use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;

diag("No strategy");
$game = Illuminated::Game->load_test('t/preco/v1/standard_test.csv');
diag("Log file is: " . $game->log_name);


my $p1 = $game->players->[0];
my $p2 = $game->players->[1];

diag("Templar flies away from all using coriolis, after that templar can't use coriolis again");
$game->configure_scenario([6, 6], [0], ['C epsilon', 'P2 F', 'P1 C delta', 'quit']);
$game->run;
is($game->get_distance($p1, $game->foes->[4]), 'near', $game->foes->[4]->name . " is near from " . $p1->name);
is($game->get_distance($p1, $game->foes->[6]), 'near', $game->foes->[6]->name . " is near from " . $p1->name);
is($game->get_distance($p1, $game->foes->[7]), 'near', $game->foes->[7]->name . " is near from " . $p1->name);
is($game->get_distance($p1, $game->foes->[8]), 'near', $game->foes->[8]->name . " is near from " . $p1->name);
is($game->get_distance($p2, $game->foes->[4]), 'far', $game->foes->[4]->name . " is far from " . $p2->name);
is($game->get_distance($p2, $game->foes->[6]), 'far', $game->foes->[6]->name . " is far from " . $p2->name);
is($game->get_distance($p2, $game->foes->[7]), 'far', $game->foes->[7]->name . " is far from " . $p2->name);
is($game->get_distance($p2, $game->foes->[8]), 'far', $game->foes->[8]->name . " is far from " . $p2->name);
is($game->active_player_device_chance, 0, 'active player device chance flag is 0');
is($game->memory_log->[-4], 'Bad option', 'Second use of devices forbidden');
is($p2->energy, 4, 'Energy consumed for coriols thruster');
diag("Next turn Templar uses coriolis to get near delta");
$game->configure_scenario([6, 6, 6, 6, 6, 6], [0, 0], ['C ro', 'F delta', 'P2 C delta', 'A1 delta', 'quit']);
$game->run;
is($game->get_distance($p2, $game->foes->[5]), 'near', $game->foes->[5]->name . " is near from " . $p2->name);
is($game->get_distance($p2, $game->foes->[4]), 'near', $game->foes->[4]->name . " is near from " . $p2->name);
is($p2->energy, 3, 'Energy consumed for coriols thruster');
is($game->foes->[4]->health, 1, $game->foes->[4]->name . " hit after coriolis approach"); 

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");

done_testing();
