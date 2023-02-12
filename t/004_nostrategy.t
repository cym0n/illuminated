use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;

diag("No strategy");
$game = Illuminated::Game->init_test('standard_game', 
    [6, 6, 6, 4, 4, 4, 2, 2, 2,
     6, 6, 6, 4, 4, 4, 2, 2, 2,], 
    ['N', 'N', 'quit']);
diag("Log file is: " . $game->log_name);
$game->run();
my $p1 = $game->players->[0];
my $p2 = $game->players->[1];

is($game->foes->[0]->aware, 0, $game->foes->[0]->name . " is unaware");

is($game->foes->[1]->aware, 0, $game->foes->[1]->name . " is unaware");

is($game->foes->[2]->aware, 0, $game->foes->[2]->name . " is unaware");

is($game->foes->[3]->aware, 1, $game->foes->[3]->name . " is aware");
is($game->get_distance($p1, $game->foes->[3]), 'far', $game->foes->[3]->name . " is far from " . $p1->name);
is($game->get_distance($p2, $game->foes->[3]), 'far', $game->foes->[3]->name . " is far from " . $p2->name);

is($game->foes->[4]->aware, 1, $game->foes->[4]->name . " is aware");
is($game->get_distance($p1, $game->foes->[4]), 'far', $game->foes->[4]->name . " is far from " . $p1->name);
is($game->get_distance($p2, $game->foes->[4]), 'far', $game->foes->[4]->name . " is far from " . $p2->name);

is($game->foes->[5]->aware, 1, $game->foes->[5]->name . " is aware");
is($game->get_distance($p1, $game->foes->[5]), 'far', $game->foes->[5]->name . " is far from " . $p1->name);
is($game->get_distance($p2, $game->foes->[5]), 'far', $game->foes->[5]->name . " is far from " . $p2->name);

is($game->foes->[6]->aware, 1, $game->foes->[6]->name . " is aware");
is($game->get_distance($p1, $game->foes->[6]), 'near', $game->foes->[6]->name . " is near from " . $p1->name);
is($game->get_distance($p2, $game->foes->[6]), 'near', $game->foes->[6]->name . " is near from " . $p2->name);

is($game->foes->[7]->aware, 1, $game->foes->[7]->name . " is aware");
is($game->get_distance($p1, $game->foes->[7]), 'near', $game->foes->[7]->name . " is near from " . $p1->name);
is($game->get_distance($p2, $game->foes->[7]), 'near', $game->foes->[7]->name . " is near from " . $p2->name);

is($game->foes->[8]->aware, 1, $game->foes->[8]->name . " is aware");
is($game->get_distance($p1, $game->foes->[8]), 'near', $game->foes->[8]->name . " is near from " . $p1->name);
is($game->get_distance($p2, $game->foes->[8]), 'near', $game->foes->[8]->name . " is near from " . $p2->name);

done_testing();
