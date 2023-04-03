use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;
my $log;

diag("Testing station setting");
$game = Illuminated::Game->station_test();
diag("Log file is: " . $game->log_name);

diag("Landing procedure as in 013_station, no tests");
$game->configure_scenario([6, 6, 6, 6, 6, 6], [2, 3, 0, 1, 2, 3], ['C tortuga', 'C tortuga', 'L tortuga', 'L tortuga', 'quit']);
$game->run;

diag("Paladin and Templar cover, gamma and delta can't shoot them, they pursuit");
$game->configure_scenario([], [0, 1, 0, 1], ['V', 'V', 'quit']);
$game->run;
ok($game->find_log('alpha: pursuit from above (landing)', "=== RUN ==="), 'alpha pursuit');
ok($game->find_log('beta: pursuit from above (landing)' , "=== RUN ==="), 'beta pursuit');

diag("Paladin can't cover anymore and lift, Templar stay covered but gamma reaches him");
$game->configure_scenario([4, 4, 4], [2, 0, 2], ['V', 'L', 'V', 'quit']);
$game->run;








is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");
done_testing();
