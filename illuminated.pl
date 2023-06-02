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
if($ia)
{
    say "Generating random IA string";
    my $string = ia_string($length);
    $game = Illuminated::Game->init_ia($game_type, $string);
}
else
{
    $game = Illuminated::Game->new();
    $game->$game_type();
}
$game->run();

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

