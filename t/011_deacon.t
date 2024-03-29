use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;
use Data::Dumper;

my $game;

diag("No strategy");
#$game = Illuminated::Game->ship_test();
$game = Illuminated::Game->load_test('t/preco/v1.1/ship_test.csv');
diag("Log file is: " . $game->log_name);
my $ship = $game->get_other('joyful sacrifice');
my $p1 = $game->players->[0];
my $p2 = $game->players->[1];

diag("Players moving up and down until Arabelle appears");
$game->configure_scenario([6, 6, 6, 6, 6, 6, 6, 6, 6], [0, 0, 1, 1, 2, 0], 
    [ 'C joyful sacrifice', 'C joyful sacrifice',
      'F joyful sacrifice', 'F joyful sacrifice', 
      'C joyful sacrifice', 'C joyful sacrifice', 
    'quit']);
$game->run;

my $deacon = $game->get_foe('Arabelle');

ok($deacon, $deacon->name . " is on the stage");
is($game->get_distance($p1, $deacon), 'near', $p1->name . " is near " . $deacon->name . " (copied from ship distance");
is($game->get_distance($p2, $deacon), 'near', $p2->name . " is near " . $deacon->name . " (copied from ship distance");

diag("Arabelle uses drain");
$game->configure_scenario([6, 6, 6], [12], 
    [ 'F joyful sacrifice', 'F joyful sacrifice',
    'quit']);
$game->run;
ok($game->find_log('Arabelle use device: drain', "=== RUN ==="),'Arabelle use device: drain');
is($p1->energy, 4, "Energy of " . $p1->name . " drained");
is($p2->energy, 4, "Energy of " . $p2->name . " drained");
is($deacon->energy, 2, "Energy of " . $deacon->name . " used");
ok($deacon->has_status('overheat'), $deacon->name . " overheat");

diag("Arabelle assaults Paladin");
$game->configure_scenario([6, 6, 5, 5, 5, 1, 1, 1], [12, 0], 
    [ 'C Arabelle', 'A1 Arabelle', 'D',
    'quit']);
$game->run;
is($game->get_distance($p1, $deacon), 'close', $p1->name . " is close to " . $deacon->name);
is($deacon->health, 5, $deacon->name . " got 1 damage");
is($p1->health, 6, $p1->name . " got 4 damages (two sword slash)");
diag("Arabelle drain used again after overheat expired");
$game->configure_scenario([6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5], [12, 12], 
    [ 'A1 Arabelle', 'A1', 'F Arabelle',
    'quit']);
$game->run();
ok($game->find_log('Arabelle use device: drain', "=== RUN ==="),'Arabelle use device: drain');
is($p1->energy, 3, "Energy of " . $p1->name . " drained");
is($p2->energy, 3, "Energy of " . $p2->name . " drained");
is($deacon->energy, 1, "Energy of " . $deacon->name . " used");
is($deacon->health, 2, $deacon->name . " got 3 damage");
is($p1->health, 4, $p1->name . " got 2 damages");

diag("Grab ability of Arabelle showed");
$game->configure_scenario([5, 4], [], 
    [ 'D',
    'quit']);
$game->run();
is($game->get_distance($p1, $deacon), 'close', $p1->name . " is close to " . $deacon->name);

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");

done_testing();

