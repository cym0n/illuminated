use strict;
use v5.10;
use lib 'lib';

use Test::More;

diag("Main library load");
require_ok('Illuminated::Game');
my $game = Illuminated::Game->new();
$game->standard_game();

diag("Two players created");
is(@{$game->players}, 2);

done_testing;
