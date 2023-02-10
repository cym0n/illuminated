use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

diag("Main library load");
my $game = Illuminated::Game->new({ loaded_dice => [6, 6, 6, 6]});
$game->standard_game(['S', 'S']);
$game->run();
done_testing();
