#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';

use Illuminated::Game;
use Getopt::Long;

my $ia;
my $length = 100;
GetOptions("ia" => \$ia, "length=i" => \$length); 
my $game_type = shift || 'standard_game';

my $game;
my $start_enemies;
if($ia)
{
    say "Generating random IA string";
    my $string = ia_string($length);
    $game = Illuminated::Game->init_ia($game_type, $string);
    $start_enemies = int(@{$game->foes});
    $game->run();
    ia_report($game);
}
else
{
    $game = Illuminated::Game->new();
    $game->$game_type();
    $game->run();
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
    say "-------";
    if(! @{$game->foes})
    {
        say "VICTORY SCENARIO";
        say "Turns played: " . $game->turn;
    }
    if(! @{$game->players})
    {
        say "DEFEAT SCENARIO";
        say "Turns played: " . $game->turn;
        say "Enemies still alive: " . int(@{$game->foes}) . "/" . int(@{$game->current_tile->foes});
        say "IA miss: " . $game->ia_miss;
        say "Bad options: " . $game->bad_options;
    }    
}

