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
                     'd' => 0,
                     'u' => 0, 
                     'foes' => 0,
                     'games' => 0);

    for(my $j = 0; $j < $generations; $j++)
    {
        say "\nGenerating random IA string number $j";
        my $string = ia_string($length);
        for(my $i = 0; $i < $tries; $i++)
        {
            my $game = Illuminated::Game->init_ia($games{$game_type}, $string, $i, $load, $clever);
            $game->run();
            my ($outcome, $foes) = ia_report($game);
            $counters{$outcome} = $counters{$outcome} + 1;
            $counters{'games'} =  $counters{'games'} + 1;
            $counters{'foes'} =  $counters{'foes'} + $foes;
        }
    }
    say "=======";
    say "VICTORIES: " . $counters{'v'};
    say "DEFEATS: " . $counters{'d'};
    say "UNFINISHED: " . $counters{'u'};
    say "AVERAGE SURVIVED ENEMIES: " . $counters{'foes'} / ( $counters{'d'} + $counters{'u'});
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
    my @commands = ('AW', #Attack the weakest 
                    'AS', #Attack the strongest
                    'CN', #Get closer to a near enemy
                    'CF', #Get closer to a far enemy
                    'FF'  #Get away from all
    );

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
    my $outcome;
    my $title;
    if(! @{$game->foes})
    {
        $outcome = 'v';
        $title = "VICTORY SCENARIO";
    }
    elsif(! @{$game->players})
    {
        $outcome = 'd';
        $title = "DEFEAT SCENARIO";
    }
    else
    {
        $outcome = 'u';
        $title = "UNFINISHED SCENARIO";
    }
    if($to_print eq 'a' || $to_print eq $outcome)
    {
        say "-------";
        say $title;
        say "Turns played: " . $game->turn;
        say "Enemies still alive: " . int(@{$game->foes}) . "/" . int(@{$game->current_tile->foes}) if($outcome eq 'd' || $outcome eq 'u');
        say "Log: " . $game->log_name;
    }
    my $foes = $outcome eq 'v' ? 0 : int(@{$game->foes});
    return ($outcome, $foes)
}

