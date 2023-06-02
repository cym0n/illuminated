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
GetOptions("ia" => \$ia, "length=i" => \$length, "tries=i" => \$tries, "gens=i" => \$generations, "to-print=s" => \$to_print); 
my $game_type = shift || 'standard_game';

my $start_enemies;
if($ia)
{
    for(my $j = 0; $j < $generations; $j++)
    {
        say "\nGenerating random IA string number $j";
        my $string = ia_string($length);
        for(my $i = 0; $i < $tries; $i++)
        {
            my $game = Illuminated::Game->init_ia($game_type, $string, $i);
            $start_enemies = int(@{$game->foes});
            $game->run();
            ia_report($game);
        }
    }
}
else
{
    my $game = Illuminated::Game->new();
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
    if(! @{$game->foes})
    {
        return if $to_print eq 'd' || $to_print eq 'u';
        say "-------";
        say "VICTORY SCENARIO";
        say "Turns played: " . $game->turn;
        say "Log: " . $game->log_name;
        return;
    }
    if(! @{$game->players})
    {
        return if $to_print eq 'v' || $to_print eq 'u';
        say "-------";
        say "DEFEAT SCENARIO";
        say "Turns played: " . $game->turn;
        say "Enemies still alive: " . int(@{$game->foes}) . "/" . int(@{$game->current_tile->foes});
        say "Log: " . $game->log_name;
        return;
    }
    return if $to_print eq 'v' || $to_print eq 'd';
    say "-------";
    say "UNFINISHED SCENARIO";
    say "Turns played: " . $game->turn;
    say "Enemies still alive: " . int(@{$game->foes}) . "/" . int(@{$game->current_tile->foes});
    say "Log: " . $game->log_name;
}

