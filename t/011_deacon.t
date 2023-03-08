use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;
use Data::Dumper;

my $game;

diag("No strategy");
$game = Illuminated::Game->ship_test();
diag("Log file is: " . $game->log_name);
my $ship = $game->get_other('joyful sacrifice');
my $p1 = $game->players->[0];
my $p2 = $game->players->[1];

diag("Players moving up and down until Arabell appears");
$game->configure_scenario([6, 6, 6, 6, 6, 6, 6, 6, 6], [0, 0, 1, 1, 2, 0], 
    [ 'C joyful sacrifice', 'C joyful sacrifice',
      'F joyful sacrifice', 'F joyful sacrifice', 
      'C joyful sacrifice', 'C joyful sacrifice', 
    'quit']);
$game->run;

my $deacon = $game->get_foe('Arabelle');

ok($deacon, $deacon->name . " is on the stage");

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");
is($game->get_distance($p1, $deacon), 'near', $p1->name . " is near " . $deacon->name . " (copied from ship distance");
is($game->get_distance($p2, $deacon), 'near', $p2->name . " is near " . $deacon->name . " (copied from ship distance");
$game->configure_scenario([6, 6, 6], [12], 
    [ 'F joyful sacrifice', 'F joyful sacrifice',
    'quit']);
$game->run;
is($game->memory_log->[-7], 'Arabelle use device: drain', 'Arabelle use device: drain');
is($p1->energy, 4, "Energy of " . $p1->name . " drained");
is($p2->energy, 4, "Energy of " . $p2->name . " drained");
is($deacon->energy, 2, "Energy of " . $deacon->name . " used");
ok($deacon->has_status('overheat'), $deacon->name . " overheat");


done_testing();

