package Illuminated::Device::CoriolisThruster;

use v5.10;
use Moo;
extends 'Illuminated::Device';

has name => (
    is => 'ro',
    default => 'coriolis thruster'
);

has energy_usage => (
    is => 'ro',
    default => 1
);

around preconditions => sub {
    my $orig = shift;
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    my @targets = $game->at_distance($subject, 'close');
    return 0 if @targets;
    return $self->$orig($game, $subject, $arg);
};

sub check_command
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    $arg = uc($arg);
    if($arg =~ /^F$/)
    {
        return 1;
    }
    elsif($arg =~ /^C (.*)$/)
    {
        my $target_name = $1;
        my ($player, $foe) = $game->detect_player_foe($subject, $target_name);
        my $target = $player->tag eq $subject->tag ? $foe : $player;
        return 1 if $target;
    }
    return 0;
}

sub get_targets
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    $arg = uc($arg);
    if($arg =~ /^F$/)
    {
        return $game->at_distance($subject, 'near');
    }
    elsif($arg =~ /^C (.*)$/)
    {
        my $target_name = $1;
        my ($player, $foe) = $game->detect_player_foe($subject, $target_name);
        my $target = $player->tag eq $subject->tag ? $foe : $player;
        return ( $target );
    }
    else
    {
        return ();
    }
}


sub action
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    $arg = uc($arg);
    if($arg =~ /^F$/)
    {
        $game->log($subject->name . " fly away from all using " . $self->name);
        for($self->get_targets($game, $subject, $arg))
        {
            $game->move($subject, $_, 'farther');
            $game->log($_->name . " now " . $game->get_distance($_, $subject) . " for " . $subject->name); 
        }
    }
    elsif($arg =~ /^C (.*)$/)
    {
        my @targets = $self->get_targets($game, $subject, $arg);
        $game->log($subject->name . " gets near " . $targets[0]->name . " using " . $self->name);  
        $game->move($subject, $targets[0], 'closer');
        $game->log($targets[0]->name . " now " . $game->get_distance($targets[0], $subject) . " for " . $subject->name); 
    }
}

1;
