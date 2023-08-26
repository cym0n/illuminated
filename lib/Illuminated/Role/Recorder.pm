package Illuminated::Role::Recorder;

use strict;
use v5.10;

use Moo::Role;
use Data::Dumper;

requires 'distance_matrix';
requires 'ground_position';
requires 'dump';
requires 'players';
requires 'foes';
requires 'add_player';
requires 'player_templates';
requires 'add_foe';
requires 'init_log';
requires 'log';
requires 'add_other';

my $dump_version = '1.1';

sub write_all
{
    my $self = shift;
    my $savefile = shift;
    return "No file provided" if ! $savefile;
    open(my $io, "> $savefile");
    print {$io} "####### V$dump_version\n";
    $self->write_game($io);
    $self->write_distance_matrix($io);
    for(@{$self->players})
    {
        $self->write_player($_->dump, 'PLAYER', $io);
    }
    for(@{$self->foes})
    {
        $self->write_player($_->dump, 'FOE', $io);
    }
    for(@{$self->others})
    {
        $self->write_player($_->dump, 'OTHER', $io);
    }
    $self->write_ground_position($io);
    close($io);
}
sub write_game
{
    my $self = shift;
    my $game = $self->dump;
    my $io = shift;  
    print {$io} "GAME;" . join(";", $game->{current_tile}, $game->{active_player_counter}, $game->{active_player_device_chance}, $game->{turn}) . "\n";
}
sub write_distance_matrix
{
    my $self = shift;
    my $io = shift;
    print {$io} "### DISTANCE MATRIX\n";
    foreach my $i (sort keys %{$self->distance_matrix})
    {
        foreach my $j (sort keys %{$self->{distance_matrix}->{$i}})
        {
            print {$io} join(";", $i, $j, $self->{distance_matrix}->{$i}->{$j}) . "\n"
        }
    }
    print {$io} "### END DISTANCE MATRIX\n";
}
sub write_ground_position
{
    my $self = shift;
    my $io = shift;
    print {$io} "### GROUND POSITION\n";
    foreach  my $i (sort keys %{$self->ground_position})
    {
        print {$io} join(";", $i, $self->ground_position->{$i}->tag) . "\n";
    } 
    print {$io} "### END GROUND POSITION\n";
}



sub write_player
{
    my $self = shift;
    my $player = shift;
    my $player_or_foe = shift;
    my $io = shift;

    my @data = qw(class name type health);
    if($player_or_foe eq 'PLAYER')
    {
        @data = (@data, 'energy', 'cover');
    }
    if($player_or_foe eq 'FOE')
    {
        @data = (@data, 'energy', 'cover', 'aware', 'action_points', 'focus')
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
    if($player_or_foe ne 'OTHER')
    {
        foreach my $w (@{$player->{weapons}})
        {
            print {$io} "WEAPON;" . join(";", $w->{class}, $w->{name}) . "\n";
            $self->write_status($w->{status}, $io);
        }
        print {$io} "DEVICES;" . join(";", @{$player->{devices}}) . "\n"; 
    }
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

sub load
{
    my $self = shift;
    my $savefile = shift;

    $self->init_log;

    open(my $io, "< $savefile");
    my $version;
    my $subsection = undef;
    my $obj = undef;
    for(<$io>)
    {
        chomp;
        my $line = $_;
        if(! $subsection)
        {
            if($line =~ /^####### V(.*)$/)
            {
                $version = $1;
                if($version ne $dump_version)
                {
                    say "WARNING: Dump of version $version";
                }
                next;
            }
            elsif($line =~ /^GAME;/)
            {
                my @data = split(";", $line);
                eval("require $data[1]");
                my $tile = $data[1]->new();
                $tile->entered(1);
                $self->current_tile($tile);
                $self->active_player_counter($data[2]);
                $self->active_player_device_chance($data[3]);
                $self->turn($data[4]);
            }
            elsif($line =~ /^### DISTANCE MATRIX$/)
            {
                $subsection = 'distance matrix';
            }
            elsif($line =~ /^### GROUND POSITION$/)
            {
                $subsection = 'ground position';
            }
            elsif($line =~ /^### PLAYER$/)
            {
                $subsection = 'player';
            }
            elsif($line =~ /^### FOE$/)
            {
                $subsection = 'foe';
            }
            elsif($line =~ /^### OTHER$/)
            {
                $subsection = 'other';
            }
        }
        else
        {
            if($line =~ /^### END/)
            {
                $subsection = undef;
                $obj = undef;
            }
            else
            {
                my @data = split(";", $line);
                if($subsection eq 'distance matrix')
                {
                    $self->distance_matrix->{$data[0]}->{$data[1]} = $data[2];
                }
                elsif($subsection eq 'ground position')
                {
                    $self->ground_position->{$data[0]} = $data[1];
                }
                elsif($subsection eq 'player')
                {
                    if($data[0] eq 'DATA')
                    {
                        $obj = $self->add_player($data[2], $data[3], $self->player_templates->{$data[3]});
                        $obj->health($data[4]);
                        $obj->energy($data[5]);
                    }
                    elsif($data[0] eq 'WEAPON')
                    {
                        eval("require $data[1]");
                        $obj->add_weapon($data[1]->new());
                    }
                    elsif($data[0] eq 'DEVICES')
                    {
                        for(my $i = 1; $i < scalar @data; $i++)
                        {
                            eval("require $data[$i]");
                            $obj->add_device($data[$i]->new());
                        }
                    }
                }
                elsif($subsection eq 'foe')
                {
                    if($data[0] eq 'DATA')
                    {
                        $obj = $self->add_foe($data[2], $data[1], 1);
                        $obj->health($data[4] || 0);
                        $obj->energy($data[5] || 0);
                        $obj->cover($data[6] || 0);
                        $obj->aware($data[7] || 0);
                        $obj->action_points($data[8] || 0);
                        $obj->focus($data[9]);
                    }
                }
                elsif($subsection eq 'other')
                {
                    if($data[0] eq 'DATA')
                    {
                        $obj = $self->add_other($data[2], $data[1], 1);
                        $obj->health($data[4] || 0);
                    }
                }
            }
        }
    }
    $self->log("Game loaded from: $savefile");
}
