use strict;
use v5.10;
use lib 'lib';

use Test::More;
use File::Compare;
use Illuminated::Game;

`rm -f t/tmp/*`;

my $game;
my $log;

diag("Testing station setting");
$game = Illuminated::Game->load_test('t/preco/v1.1/status_test.csv');
diag("Log file is: " . $game->log_name);

my $p1 = $game->players->[0];
my $p2 = $game->players->[1];
my $gamma = $game->foes->[2];
my $epsilon = $game->foes->[3];

ok($p2->has_status('no-cover'), $p2->name . ": no cover available");
is($p2->status_duration('no-cover'), 2, $p2->name . " no cover for 2 turns");
ok($gamma->has_status('jammed'), $gamma->name . " is jammed");
is($gamma->status_duration('jammed'), 3, $gamma->name . " is jammed for 3 turns");
ok($epsilon->has_status('jammed'), $epsilon->name . " is jammed");
is($epsilon->status_duration('jammed'), 3, $epsilon->name . " is jammed for 3 turns");
ok($p1->get_weapon('balthazar')->has_status('smoking'), $p1->name . "'s balthazar is smoking");
is($p1->get_weapon('balthazar')->status_duration('smoking'), 2, $p1->name . "'s balthazar is smoking for 2 turns");
$game->write_all("t/tmp/015save.csv");
diag("Save file correctly generated (compared with preco)");
is(compare("t/tmp/015save.csv", "t/preco/v1.1/status_test.csv"), 0);

done_testing();
