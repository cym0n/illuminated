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
my $alpha = $game->foes->[0];
my $epsilon = $game->foes->[3];


diag("Paladia jams foes communications");
$game->configure_scenario([], [], ['P1', 'quit']);
$game->run;
ok(! $alpha->has_status('jammed'), $alpha->name . " is not jammed as unaware");
ok($epsilon->has_status('jammed'), $epsilon->name . " is jammed");
is($p1->energy, 4, "Paladin spent an energy unit for jamming");

diag("Paladin and Templar fly around until jamming effect fades");
$game->configure_scenario( 
[6, 6, 6, 
 6, 6, 6,
 6, 6, 6,
], 
[3, 1, 
 3, 
 3], 
['F _all', 'F _all',
 'C delta', 'C delta',
 'F _all', 'F _all',
 'quit'
] );
$game->run;
is($alpha->aware, 0, "Alpha still unaware as Epsilong couldn't reach it");
ok(! $epsilon->has_status("jammed"), "Jamming faded");

diag("Epsilon alerts alpha as he is not jammed anymore");
$game->configure_scenario([6, 6, 6, 2], [3, 0], ['C delta', 'C delta', 'quit']);
$game->run;
is($alpha->aware, 1, "Alpha now aware because of Epsilon");

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");
done_testing();
