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
$game = Illuminated::Game->load_test('t/preco/v1.1/station_test.csv');
diag("Log file is: " . $game->log_name);

my $p1 = $game->players->[0];
my $p2 = $game->players->[1];
my $alpha = $game->foes->[0];
my $gamma = $game->foes->[2];

diag("Landing procedure as in 013_station, no tests");
$game->configure_scenario([6, 6, 6, 6, 6, 6], [2, 3, 0, 1, 2, 3], ['V', 'C tortuga', 'C tortuga', 'L tortuga', 'L tortuga', 'quit']);
$game->run;

diag("Paladin and Templar cover, gamma and delta can't shoot them, they pursuit");
$game->configure_scenario([], [0, 1, 0, 1], ['V', 'V', 'quit']);
$game->run;
ok($p1->cover, $p1->name . " has cover");
ok($p2->cover, $p2->name . " has cover");
ok($game->find_log('alpha: pursuit from above (landing)', "=== RUN ==="), 'alpha pursuit');
ok($game->find_log('beta: pursuit from above (landing)' , "=== RUN ==="), 'beta pursuit');

diag("Paladin can't cover anymore and lift, Templar stay covered but gamma reaches him");
$game->configure_scenario([4, 4, 4], [2, 0, 2], ['V', 'L', 'V', 'S', 'quit']);
$game->run;
ok(! $game->on_ground($p1), $p1->name . " is not on ground anymore");
is($game->get_distance($p2, $gamma), 'close', $gamma->name . " is close to " . $p1->name);
ok(! $p2->cover, $p2->name. " cover broken");
ok($p2->has_status('no-cover'), $p2->name . ": no cover available");
$game->write_all("t/tmp/014save.csv");
diag("Save file correctly generated");
is(compare("t/tmp/014save.csv", "t/saves/v1.1/014.csv"), 0);

diag("Templar smashes gamma but cannot cover once free, receiving damage");
diag("Alpha close to Paladin cannot attack from above");
$game->configure_scenario([4, 4, 6, 6, 6, 6, 6, 6], [2, 2, 0, 2], ['C alpha', 'A1', 'C alpha', 'V', 'A1 delta', 'quit']);
$game->run;
is($p2->health, 5, $p2->health . " is not 5");
ok(! $p2->has_status('no-cover'), $p2->name . ": cover available");
is($game->get_distance($p1, $alpha), 'near', $alpha->name . " is near to " . $p1->name);


diag("Templar gets back cover while Paladin goes on hunting alpha");
$game->configure_scenario([6, 6], [1, 1], ['C alpha', 'V', 'quit']);
$game->run;
ok($p2->cover, $p2->name . " has cover");
ok($game->find_log('beta: pursuit from below (lifting)', "=== RUN ==="), 'beta confused, following Paladin');
ok($game->find_log('beta: pursuit from above (landing)', "=== RUN ==="), 'beta confused, following Templar');

is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");
done_testing();

