package Illuminated::Device::FleuretThruster;

use v5.10;
use Moo;
extends 'Illuminated::Device';

has name => (
    is => 'ro',
    default => 'fleuret thruster'
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
    my @targets_close = $game->at_distance($subject, 'close');
    my @targets_near = $game->at_distance($subject, 'near');
    return 0 if ! @targets_close && ! @targets_near;
    return $self->$orig($game, $subject, $arg);
};

sub check_command
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    if($arg =~ /^D$/)
    {
        my @targets_close = $game->at_distance($subject, 'close');
        return 1 if @targets_close;
    }
    elsif($arg =~ /^C (.*)$/)
    {
        my $target_name = $1;
        my ($player, $foe) = $game->detect_player_foe($subject, $target_name);
        my $target = $player->tag eq $subject->tag ? $foe : $player;
        return 1 if $target && $game->get_distance($player, $foe) eq 'near';
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
    if($arg =~ /^D$/)
    {
        return $game->at_distance($subject, 'close');
    }
    elsif($arg =~ /^C (.*)$/)
    {
        my $target_name = $1;
        my ($player, $foe) = $game->detect_player_foe($subject, $target_name);
        my $target = $player->tag eq $subject->tag ? $foe : $player;
        return ( $target );
    }
}


sub action
{
    my $self = shift;
    my $game = shift;
    my $subject = shift;
    my $arg = shift;
    $arg = uc($arg);
    my ( $target ) = $self->get_targets($game, $subject, $arg);
    if($arg =~ /^D$/)
    {
        $game->log($subject->name . " disangaging from " . $target->name . " useing " . $self->name);
        $game->move($subject, $target, 'farther');
        $game->log($target->name . " now " . $game->get_distance($target, $subject) . " for " . $subject->name); 
    }
    elsif($arg =~ /^C (.*)$/)
    {
        $game->log($subject->name . " gets near " . $target->name . " using " . $self->name);  
        $game->move($subject, $target, 'closer');
        $game->log($target->name . " now " . $game->get_distance($target, $subject) . " for " . $subject->name); 
        if($target->has_status('parry'))
        {
            $game->log('Parry status for ' . $target->name . ' broken');
            $target->deactivate_status('parry');
        }
    }
}

1;
