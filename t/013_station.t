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



is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");

done_testing();
