use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Illuminated::Game;

my $game;

diag("No strategy");
$game = Illuminated::Game->load_test('t/preco/v1.1/standard_test.csv');
diag("Log file is: " . $game->log_name);


my $p1 = $game->players->[0];
my $p2 = $game->players->[1];
my $csi = $game->foes->[7];
my $delta = $game->foes->[4];

diag("Palading gets close to csi with consequences, csi's aegis raised");
$game->configure_scenario( [4, 4], [], ['C csi', 'quit'], "Palading gets close to csi with consequences, csi's aegis raised" );
$game->run;
is($game->get_distance($p1, $csi), 'close', $csi->name . " is close from " . $p1->name);
is($csi->has_status('parry'), 1, $csi->name . " has parry" );

diag("Templat gets close to delta without consequences.");
diag("End turn action point wasted");
$game->configure_scenario( [6], [0], ['C delta', 'quit'], "Templat gets close to delta without consequences." );
$game->run;

diag("Uneffective slash of Paladin on csi with parry");
$game->configure_scenario( [6, 6, 6], [0], ['A1', 'quit'], "Uneffective slash of Paladin on csi with parry" );
$game->run;
is($csi->health, 2, $csi->name . " untouched");
is($csi->has_status('parry'), 0, $csi->name . " has no more parry" );

diag("Templar try to fly away, command not available");
diag("Templar smashing delta with sword");
diag("End turn action point wasted");
$game->configure_scenario( [6], [0, 0], ['interface', 'F delta', 'A1', 'quit'], "Templar smashing delta with sword" );
$game->run;
is($delta->health, 0, $delta->name . " took damage");
is($delta->active, 0, $delta->name . " killed");

diag("Paladin disengages with consequences, csi raises the aegis again");
$game->configure_scenario( [4, 4, 4], [], ['D', 'quit'], "Paladin disengages with consequences, csi raises the aegis again" );
$game->run;
is($game->get_distance($p1, $csi), 'near', $csi->name . " is near from " . $p1->name);
is($csi->has_status('parry'), 1, $csi->name . " has parry" );

diag("Template get close to csi with consequences, csi smashes him with the sword");
$game->configure_scenario( [4], [0], ['S', 'C csi', 'quit'], "Template get close to csi with consequences, csi smashes him with the sword" );
$game->run;
is($p2->health, 8, $p2->name . " got two damages from csi sword");
is($game->random_dice_counter, 0, "No real dice");
is($game->true_random_counter, 0, "No true random numbers");

done_testing();
