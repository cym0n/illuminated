use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;
my $log;

diag("Testing station setting");
$game = Illuminated::Game->station_test();
diag("Log file is: " . $game->log_name);
$game->run;

my $p1 = $game->players->[0];
my $p2 = $game->players->[1];
my $gamma = $game->foes->[2];
my $delta = $game->foes->[3];
my $airlock = $game->others->[1];

diag("Paladin and Templar landing on space station under carriers fire");
$game->configure_scenario([4, 4, 4, 4, 4, 4], [0, 0, 1, 1, 0, 1, 0, 1, 0, 1], ['C tortuga', 'C tortuga', 'L tortuga', 'L tortuga', 'quit']);
$game->run;

$log = "alpha deals 1 damage to Paladin using balthazar!";
ok($game->find_log($log, "=== RUN ==="), $log);
$log = "beta deals 1 damage to Templar using balthazar!";
ok($game->find_log($log, "=== RUN ==="), $log);
$log = "alpha deals 2 damage to Paladin using gospel!";
ok($game->find_log($log, "=== RUN ==="), $log);
$log = "beta deals 2 damage to Templar using gospel!";
ok($game->find_log($log, "=== RUN ==="), $log);
is($p1->health, 5, "Paladin got five damages");
is($p2->health, 5, "Templar got five damages");
is($game->on_ground($p1)->name, 'tortuga', $p1->name . " is on tortuga");
is($game->on_ground($p2)->name, 'tortuga', $p2->name . " is on tortuga");

diag("Paladin and Templar shooting airlock while thugs chase them");
$game->configure_scenario([4, 4, 4, 4, 4, 4], [2, 0, 3, 1, 2, 3], ['C airlock', 'C airlock', 'quit']);
$game->run;
is($game->on_ground($gamma)->name, 'tortuga', $gamma->name . " is on tortuga");
is($game->on_ground($delta)->name, 'tortuga', $delta->name . " is on tortuga");
is($game->get_distance($gamma, $p1), 'near', $p1->name . " is near to " . $gamma->name);
is($game->get_distance($delta, $p2), 'near', $p2->name . " is near to " . $delta->name);

diag("Paladin and Templar shoot to airlock, gamma and delta shoot to them (as near foes)");
$game->configure_scenario([6, 6, 6, 6], [2, 3], ['A1 airlock', 'A1 airlock', 'quit']);
$game->run;
is($p1->health, 4, "Paladin got 1 damage");
is($p2->health, 4, "Templar got 1 damage");
is($airlock->health, 18, "Airlock got 2 damage");

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");

done_testing();
