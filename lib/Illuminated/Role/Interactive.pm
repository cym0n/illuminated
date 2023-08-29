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
has ia_players => (
    is => 'rw',
    default => 0,
);
has clever => (
    is => 'rw',
    default => 0
);

has ia_miss => (
    is => 'rw',
    default => 0,
);
has bad_options => (
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
        if($self->ia_players)
        {
            if($self->clever)
            {
                my $clever_value = $self->clever_auto($game);
                return $clever_value if $clever_value;
            }
            my $ia_value = $self->process_ia_command($game, $value);
            if($ia_value eq '???')
            {
                $game->ia_miss($game->ia_miss + 1);
            }
            return $ia_value;
        }
        else
        {
            return $value;
        }
    }
    else
    {
        if($self->ia_players)
        {
            return 'quit';
        }
        return undef;
    }
}
sub clever_auto
{
    my $self = shift;
    my $game = shift;
    my $p = $game->active_player;

    #If strong in close combat and enemy close strikes
    my ( $target ) = $game->at_distance($p, 'close', 0);
    if($target && $p->power == 3)
    {
        return 'A1';
    } 
    elsif($target && $p->power == 1)
    {
        return 'D';
    }
    if($p->get_device('swarmgun') && scalar( $game->at_distance($p, 'near', 0)) >= 3)
    {
        foreach my $d (keys %{$game->interface_devices})
        {
            if($game->interface_devices->{$d} eq 'swarmgun')
            {
                return $d;
            }
        }
    }
    ( $target ) = $game->at_distance($p, 'near', 1);
    if($target and $p->mind == 3)
    {
        return 'A1 ' . $target->name
    }
    elsif($target and $p->power == 3)
    {
        return 'C ' . $target->name
    }
    return undef;
}


sub process_ia_command
{
    my $self = shift;
    my $game = shift;
    my $command = shift;
    
    if($command =~ /^@/)
    {
        $command =~ s/^@//;
    }
    else
    {
        return $command;
    }

    #TODO: game al posto di self, tutti i comandi devono essere di due lettere
    #TODO: manage more weapons

    if($game->at_distance($game->active_player, 'close', 1))
    {
        if($command =~ /^A/)
        {
            return 'A1';
        }
        elsif($command =~ /^F/)
        {
            return 'D';
        }
        elsif($command =~ /^C/)
        {
            return 'A1';
        }
    }

    if($command =~ /^C(.)/)
    {
        my @order = ();
        if($1 eq 'N')
        {
            @order = ( 'near', 'far' );
        }
        elsif($1 eq 'F')
        {
            @order = ( 'far', 'near' );
        }
        for(@order)
        {
            my ( $foe ) = $game->at_distance($game->active_player, $_, 1);
            if($foe)
            {
                return 'C ' . $foe->name;
            }    
        }
        return '???'; #should never happen
    }
    if($command eq 'FF')
    {
        return 'F _all'
    }
    if($command =~ /^A(.)/)
    {
        my $criteria = $1;
        #TODO: player can have a long range weapon
        my @foes = $game->at_distance($game->active_player, 'near');
        if(@foes)
        {
            if($criteria eq 'W')
            {
                @foes = sort { $a->health <=> $b->health } @foes;
            }
            elsif($criteria eq 'S')
            {
                @foes = sort { $b->health <=> $a->health } @foes;
            }
            return 'A1 ' . $foes[0]->name
        }
        else
        {
            return '???'
        }
    }
    return '???';
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
    print "Choose: " if (! $log && $game->on_screen);
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
    $game->bad_options($game->bad_options + 1);
    return undef;
}





1;
