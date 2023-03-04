use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;

diag("No strategy");
$game = Illuminated::Game->ship_test();
diag("Log file is: " . $game->log_name);
my $ship = $game->get_other('joyful sacrifice');
my $p1 = $game->players->[0];
my $p2 = $game->players->[1];
is($ship->tag, 'X-joyful sacrifice', "Ship exists");
is($game->get_distance($p1, $ship), 'far', $p1->name . " is far from ship");
is($game->get_distance($p2, $ship), 'far', $p2->name . " is far from ship");

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");
done_testing();

