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


#[ 'alpha',   'thug',      [ 'balthazar']        ],
#[ 'beta',    'thug',      [ 'balthazar']        ],
#[ 'gamma',   'thug',      [ 'balthazar']        ],
#[ 'epsilon', 'thug',      [ 'balthazar']        ],
#[ 'delta',   'thug',      [ 'balthazar']        ],
#[ 'ro',      'gunner',    [ 'reiter' ]          ],
#[ 'iota',    'gunner',    [ 'reiter' ]          ],
#[ 'csi',     'gladiator', [ 'caliban', 'aegis' ] ],
#[ 'pi',      'gladiator', [ 'caliban', 'aegis' ] ],



is($game->foes->[0]->aware, 0, $game->foes->[0]->name . " is unaware"); #alpha

is($game->foes->[1]->aware, 0, $game->foes->[1]->name . " is unaware"); #beta

is($game->foes->[2]->aware, 0, $game->foes->[2]->name . " is unaware"); #gamma

is($game->foes->[3]->aware, 1, $game->foes->[3]->name . " is aware"); #epsilon
is($game->get_distance($p1, $game->foes->[3]), 'far', $game->foes->[3]->name . " is far from " . $p1->name);
is($game->get_distance($p2, $game->foes->[3]), 'far', $game->foes->[3]->name . " is far from " . $p2->name);

is($game->foes->[4]->aware, 1, $game->foes->[4]->name . " is aware"); #delta
is($game->get_distance($p1, $game->foes->[4]), 'near', $game->foes->[4]->name . " is near from " . $p1->name);
is($game->get_distance($p2, $game->foes->[4]), 'near', $game->foes->[4]->name . " is near from " . $p2->name);

is($game->foes->[5]->aware, 1, $game->foes->[5]->name . " is aware"); #ro
is($game->get_distance($p1, $game->foes->[5]), 'far', $game->foes->[5]->name . " is far from " . $p1->name);
is($game->get_distance($p2, $game->foes->[5]), 'far', $game->foes->[5]->name . " is far from " . $p2->name);

is($game->foes->[6]->aware, 1, $game->foes->[6]->name . " is aware"); #iota
is($game->get_distance($p1, $game->foes->[6]), 'near', $game->foes->[6]->name . " is near from " . $p1->name);
is($game->get_distance($p2, $game->foes->[6]), 'near', $game->foes->[6]->name . " is near from " . $p2->name);

is($game->foes->[7]->aware, 1, $game->foes->[7]->name . " is aware"); #csi
is($game->get_distance($p1, $game->foes->[7]), 'near', $game->foes->[7]->name . " is near from " . $p1->name);
is($game->get_distance($p2, $game->foes->[7]), 'near', $game->foes->[7]->name . " is near from " . $p2->name);

is($game->foes->[8]->aware, 1, $game->foes->[8]->name . " is aware"); #pi
is($game->get_distance($p1, $game->foes->[8]), 'near', $game->foes->[8]->name . " is near from " . $p1->name);
is($game->get_distance($p2, $game->foes->[8]), 'near', $game->foes->[8]->name . " is near from " . $p2->name);

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");

done_testing();
