#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';

use Illuminated::Game;
use Getopt::Long;

my $ia;
my $length = 100;
my $tries = 1;
my $generations = 1;
my $to_print = 'a';
my $load = undef;
my $clever = 0;
GetOptions("ia" => \$ia, "length=i" => \$length, "tries=i" => \$tries, "gens=i" => \$generations, "to-print=s" => \$to_print, "load=s" => \$load, "clever" => \$clever); 
my $game_type = shift || 'standard_game';

my %games = (
    'standard_game' => 'Illuminated::Tile::GuardedSpace',
    'ship_game' => 'Illuminated::Tile::ShipEncounter',
    'station_game' => 'Illuminated::Tile::SpaceStationAssault'
);

my $start_enemies;
if($ia)
{
    my %counters = ( 'v' => 0,
                     's' => 0,
                     'u' => 0 );
    for(my $j = 0; $j < $generations; $j++)
    {
        say "\nGenerating random IA string number $j";
        my $string = ia_string($length);
        for(my $i = 0; $i < $tries; $i++)
        {
            my $game = Illuminated::Game->init_ia($games{$game_type}, $string, $i, $load, $clever);
            $game->run();
            my $outcome = ia_report($game);
            $counters{$outcome} = $counters{$outcome} + 1;
        }
    }
    say "=======";
    say "VICTORIES: " . $counters{'v'};
    say "DEFEATS: " . $counters{'s'};
    say "UNFINISHED: " . $counters{'u'};
}
else
{
    my $game = Illuminated::Game->new();
    if($load)
    {
        $game->load($load);
        $game->run();
    }
    else
    {
        $game->one_tile($games{$game_type});
        $game->run();
    }
}

sub ia_string
{
    my $length = shift;
    my @commands = ('AW', 'AS', 'CN', 'CF', 'FF');

    my $string = '';
    for(my $i = 0; $i < $length; $i++)
    {
        my $choice = $commands[int(rand(@commands))];
        $string .= $choice; 
    }
    return $string;
}

sub ia_report
{
    my $game = shift;
    if(! @{$game->foes})
    {
        return 'v' if $to_print eq 'd' || $to_print eq 'u';
        say "-------";
        say "VICTORY SCENARIO";
        say "Turns played: " . $game->turn;
        say "Log: " . $game->log_name;
        return 'v';
    }
    if(! @{$game->players})
    {
        return 's' if $to_print eq 'v' || $to_print eq 'u';
        say "-------";
        say "DEFEAT SCENARIO";
        say "Turns played: " . $game->turn;
        say "Enemies still alive: " . int(@{$game->foes}) . "/" . int(@{$game->current_tile->foes});
        say "Log: " . $game->log_name;
        return 's';
    }
    return 'u' if $to_print eq 'v' || $to_print eq 'd';
    say "-------";
    say "UNFINISHED SCENARIO";
    say "Turns played: " . $game->turn;
    say "Enemies still alive: " . int(@{$game->foes}) . "/" . int(@{$game->current_tile->foes});
    say "Log: " . $game->log_name;
    return 'u'
}

