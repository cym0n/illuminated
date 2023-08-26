use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;

diag("No strategy");
$game = Illuminated::Game->load_test('t/preco/v1.1/standard_test.csv');
diag("Log file is: " . $game->log_name);


my $p1 = $game->players->[0];
my $p2 = $game->players->[1];
my $epsilon = $game->foes->[3];
my $delta = $game->foes->[4];
$delta->set_guard($epsilon);
my ( $delta_status ) = $delta->has_status('guard');
is($delta_status, 'guard F-epsilon', "Delta is the guard of epsilon");

diag("Paladin tries to get close to epsilon and delta reacts");
$game->configure_scenario([6, 6, 4], [0], ['C epsilon', 'quit']);
$game->run;
is($p1->health, 9, $p1->name . " hit by delta, guard of epsilon");

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");
done_testing();

