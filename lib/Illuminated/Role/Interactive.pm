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
has auto_commands => (
    is => 'ro',
    default => sub { [] }
);
has auto_commands_counter => (
    is => 'rw',
    default => 0,
);

sub auto
{
    my $self = shift;
    if($self->auto_commands->[$self->auto_commands_counter])
    {
        my $value = $self->auto_commands->[$self->auto_commands_counter];
        $self->auto_commands_counter($self->auto_commands_counter + 1);    
        return $value;
    }
    else
    {
        return undef;
    }
}

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
    my $auto = $self->auto;
    if($auto)
    {
        $answer = $auto;
    }
    else
    {
        $answer = <STDIN>;
    }
    $answer = uc($answer);
    chomp $answer;
        
    for(@{$self->interface_options})
    {
        my $reg = $_->[0]; 
        if($answer =~ /^$reg$/)
        {
            return ($1, $3);
        }
    }
    say "Bad option";
    return undef;
}





1;
