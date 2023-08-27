use strict;
use v5.10;
use lib 'lib';

use Test::More;
use File::Compare;
use Illuminated::Game;

my $game;

`rm -f t/tmp/*`;

diag("No strategy");
$game = Illuminated::Game->load_test('t/preco/v1.1/standard_test.csv');
diag("Log file is: " . $game->log_name);


my $p1 = $game->players->[0];
my $p2 = $game->players->[1];
my $delta = $game->foes->[4];
my $epsilon = $game->foes->[3];

diag("Paladin shoots delta with consequences");
$game->configure_scenario( [4, 3], [0], ['A1 delta', 'quit'] );
$game->run;
is($delta->health, 1, $delta->name . " health decreased");
is($p1->health, 9, $p1->name . " health decreased");
ok($p1->get_weapon('balthazar')->has_status('smoking'), $p1->name . "'s balthazar is smoking");
$game->write_all("t/tmp/006save.csv");
diag("Save file correctly generated");
is(compare("t/tmp/006save.csv", "t/saves/v1.1/006.csv"), 0);

diag("Templar shoots delta with consequences");
diag("Delta killed, action point to ro. Ro shoots Templar");
diag("End turn action point: epsilon flies to paladin");
$game->configure_scenario( [4, 3, 3, 3, 3], [4, 1, 3, 0], ['A1 delta', 'quit'] );
$game->run;
is($delta->health, 0, $delta->name . " health decreased");
is($delta->active, 0, $delta->name . " killed");
is($p2->health, 9, $p2->name . " health decreased (ro attack)");
diag("Paladin shoots epsilon, no consequences");
$game->configure_scenario( [6], [], ['A1 epsilon', 'quit'] );
$game->run;
is($epsilon->health, 1, $epsilon->name . " health decreased");
is($p1->health, 9, $p1->name . " health unchanged");

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");



done_testing();
