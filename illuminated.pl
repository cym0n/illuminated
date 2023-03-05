#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';

use Illuminated::Game;

my $game_type = shift || 'standard_game';

my $game = Illuminated::Game->new();

$game->$game_type();
$game->run();
