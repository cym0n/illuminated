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
        my @targets = $game->at_distance($subject, 'near');
        for(@targets)
        {
            $game->move($subject, $_, 'farther');
            $game->log($_->name . " now " . $game->get_distance($_, $subject) . " for " . $subject->name); 
        }
    }
    elsif($arg =~ /^C (.*)$/)
    {
        my $target_name = $1;
        my ($player, $foe) = $game->detect_player_foe($subject, $target_name);
        my $target = $player->tag eq $subject->tag ? $foe : $player;
        $game->log($subject->name . " gets near " . $target->name . " using " . $self->name);  
        $game->move($subject, $target, 'closer');
        $game->log($target->name . " now " . $game->get_distance($target, $subject) . " for " . $subject->name); 
    }
}

1;
