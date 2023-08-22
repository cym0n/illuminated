package Illuminated::Role::Recorder;

use strict;
use v5.10;

use Moo::Role;

requires 'players';
requires 'foes';

my $dump_version = 1;

sub write_all
{
    my $self = shift;
    my $savefile = shift;
    return "No file provided" if ! $savefile;
    open(my $io, "> $savefile");
    print {$io} "####### V$dump_version\n";
    for(@{$self->players})
    {
        $self->write_player($_->dump, 'PLAYER', $io);
    }
    for(@{$self->foes})
    {
        $self->write_player($_->dump, 'FOE', $io);
    }
    close($io);
}

sub write_player
{
    my $self = shift;
    my $player = shift;
    my $player_or_foe = shift;
    my $io = shift;

    my @data = qw(class name type health energy cover);
    if($player_or_foe eq 'FOE')
    {
        @data = (@data, 'aware', 'action_points', 'focus')
    }
    my @data_player = ();
    for(@data)
    {
        if($player->{$_})
        {
            push @data_player, $player->{$_};
        }
        else
        {
            push @data_player, '';
        }
    }
    print {$io} "### $player_or_foe\n";
    print {$io} "DATA;" . join(";", @data_player) . "\n";
    $self->write_status($player->{status}, $io);
    foreach my $w (@{$player->{weapons}})
    {
        print {$io} "WEAPON;" . join(";", $w->{class}, $w->{name}) . "\n";
        $self->write_status($w->{status}, $io);
    }
    print {$io} "DEVICES;" . join(";", @{$player->{devices}}) . "\n"; 
    print {$io} "### END $player_or_foe\n";
}

sub write_status
{
    my $self = shift;
    my $status = shift;
    my $io = shift;
    if(keys %{$status})
    {
        print {$io} "#### STATUS\n";
        foreach my $s ( keys %{$status})
        {
            print {$io} $s ."," . $status->{$s}
        }
        print {$io} "#### END STATUS\n";
    }
}
