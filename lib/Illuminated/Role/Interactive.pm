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
    is => 'rw',
    default => sub { [] }
);
has auto_commands_counter => (
    is => 'rw',
    default => 0,
);

sub auto
{
    my $self = shift;
    my $game = shift || $self;
    if($game->auto_commands->[$game->auto_commands_counter])
    {
        my $value = $game->auto_commands->[$game->auto_commands_counter];
        $game->auto_commands_counter($game->auto_commands_counter + 1);    
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
    my $log = shift;
    $self->interface_preconditions($game);
    $game->screen_only($self->interface_header);
    $self->print_options($game, $log);;
    print "Choose: " if ! $log;
}
sub print_options
{
    my $self = shift;
    my $game = shift;
    my $log = shift;
    for(@{$self->interface_options})
    {
        if($log)
        {
            $game->log($_->[1]);
        }
        else
        {
            $game->screen_only($_->[1]);
        }
    }
}


sub choice
{
    my $self = shift;
    my $game = shift;
    my $answer = undef;
    $self->interface($game);
    my $auto = $self->auto($game);
    if($auto)
    {
        $game->log("Autocommand retrieved: $auto");
        $answer = $auto;
    }
    else
    {
        $answer = <STDIN>;
    }
    $answer = uc($answer);
    chomp $answer;
    
    my @options = ( @{$game->system_options}, @{$self->interface_options});   
    for(@options)
    {
        my $reg = $_->[0]; 
        if($answer =~ /^$reg$/)
        {
            return ($1, $3);
        }
    }
    $game->log("Bad option");
    return undef;
}





1;
