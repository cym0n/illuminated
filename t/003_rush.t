use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;

diag("Successful rush for both");
$game = Illuminated::Game->init_test('standard_game', [6, 6, 6, ((4) x 8), 6, ((4) x 7)], [0, 0, 1, 1], ['R', 'R', 'quit']);
diag("Log file is: " . $game->log_name);
$game->run();
foreach my $f (@{$game->foes})
{
    is($f->aware, 1, $f->name . " is aware");
}
is(@{$game->foes}, 7, "Foes are now 7");
ok((! grep { $_->name eq 'alpha'} @{$game->foes}), "Alpha is dead");
is($game->at_distance($game->players->[0], "close"), 1, "A foe close to " . $game->players->[0]->name);
is($game->get_distance($game->players->[0], $game->get_foe('beta')), 'close', "Beta close to " . $game->players->[0]->name);

ok((! grep { $_->name eq 'gamma'} @{$game->foes}), "Gamma is dead");
is($game->at_distance($game->players->[1], "close"), 1, "A foe close to " . $game->players->[1]->name);
is($game->get_distance($game->players->[1], $game->get_foe('delta')), 'close', "Delta close to " . $game->players->[1]->name);

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");


done_testing();
