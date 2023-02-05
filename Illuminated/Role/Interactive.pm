package Illuminated::Role::Interactive;

use strict;
use v5.10;
use Moo::Role;

has interface_header => (
    is => 'rw',
    default => ""
);
has interface_options => (
    is => 'ro',
    default => sub { [] }
);

sub interface_preconditions
{
    my $self = shift;
    my $game = shift;
}
sub interface
{
    my $self = shift;
    my $game = shift;
    $self->interface_preconditions($game);
    say $self->interface_header;
    $self->print_options;
    print "Choose: ";
}
sub print_options
{
    my $self = shift;
    for(@{$self->interface_options})
    {
        say $_->[1];
    }
}
sub choice
{
    my $self = shift;
    my $game = shift;
    my $answer = undef;
    $self->interface($game);
    $answer = <STDIN>;
    $answer = uc($answer);
    chomp $answer;
    if(grep { my $reg = $_->[0]; $answer =~ /^$reg$/ } @{$self->interface_options})
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
