use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;

diag("Successful stealth");
$game = Illuminated::Game->init_test('standard_game', [6, 6, 6, 6], [], ['S', 'S', 'quit']);
diag("Log file is: " . $game->log_name);
$game->run();
foreach my $f (@{$game->foes})
{
    is($f->aware, 0, $f->name . " is not aware");
}

diag("Failed stealth, second player hasn't S option");
$game = Illuminated::Game->init_test('standard_game', [1, ((4) x 9) , 6, 6, 6], [], ['S', 'S', 'quit']);
diag("Log file is: " . $game->log_name);
$game->run();
foreach my $f (@{$game->foes})
{
    is($f->aware, 1, $f->name . " is aware");
}
is($game->memory_log->[-3], "Bad option", "S is a bad option for second player");

diag("Stealth badly failed by second player, first player all foes far");
$game = Illuminated::Game->init_test('standard_game', [6, 1, 1, 1, ((4) x 9)], [], ['S', 'S', 'quit']);
diag("Log file is: " . $game->log_name);
$game->run();
foreach my $f (@{$game->foes})
{
    is($f->aware, 1, $f->name . " is aware");
    is($game->get_distance($game->players->[0], $f), "far", $f->name . " far from " . $game->players->[0]->name);
}

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");


done_testing();
