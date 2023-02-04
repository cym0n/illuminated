package Illuminated::Tile::GuardedSpace;

use v5.10;
use Moo;
extends 'Illuminated::Tile';

sub gate_interface
{
    my $answer = undef;
    my @options =  ( 'N', 'S', 'R' ); 
    say "Entering enemy patrol zone";
    say "[N]o strategy";
    say "[S]tealth passage (mind try)";
    say "[R]ush in (power try)";
    print "Choose: ";
    $answer = <STDIN>;
    $answer = uc($answer);
    chomp $answer;
    if(grep { $answer =~ /^$_/ } @options)
    {
        return $answer;
    }
    else
    {
        say "Bad option";
        return undef;
    }
}

1;


