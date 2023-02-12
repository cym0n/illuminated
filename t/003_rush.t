use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;

diag("Successful rush for both");
$game = Illuminated::Game->init_test('standard_game', [6, 6, 6, ((4) x 8), 6, ((4) x 7)], ['R', 'R', 'quit']);
diag("Log file is: " . $game->log_name);
$game->run();
foreach my $f (@{$game->foes})
{
    is($f->aware, 1, $f->name . " is aware");
}
is(@{$game->foes}, 7, "Foes are now 7");
is($game->at_distance($game->players->[0], "close"), 1, "A foe close to " . $game->players->[0]->name);
is($game->at_distance($game->players->[1], "close"), 1, "A foe close to " . $game->players->[1]->name);


done_testing();
