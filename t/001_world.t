use strict;
use v5.10;
use lib 'lib';

use Test::More;
use File::Compare;

`rm -f t/tmp/*`;

diag("Main library load");
require_ok('Illuminated::Game');
my $game = Illuminated::Game->new();
$game->one_tile('Illuminated::Tile::GuardedSpace');

diag("Two players created");
is(@{$game->players}, 2);

$game->write_all("t/tmp/001save.cvs");
diag("Save file correctly generated");
is(compare("t/tmp/001save.cvs", "t/saves/v1.1/001.cvs"), 0);



done_testing;
