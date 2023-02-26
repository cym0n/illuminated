package Illuminated::Stand::Foe;

use v5.10;
use Moo;
extends 'Illuminated::Stand';

has tag => (
    is => 'lazy'
);
sub _build_tag
{
    my $self = shift;
    return 'F-' . lc($self->name);
}
has game_type => (
    is => 'lazy'
);
sub _build_game_type
{
    my $self = shift;
    return 'foe'
}
has aware => (
    is => 'rw',
    default => 0,
);
has focus => (
    is => 'rw',
    default => undef,
);
has action_points => (
    is => 'rw',
    default => 0,
);

with 'Illuminated::Role::IA';

sub BUILD {
  my ($self, $args) = @_;
}

sub aware_text
{
    my $self = shift;
    if($self->aware)
    {
        return 'aware';
    }
    else
    {
        return 'unaware';
    }
}

sub get_main_weapon
{
    my $self = shift;
    return $self->weapons->[0];
}

sub get_weapon_by_type
{
    my $self = shift;
    my $type = shift;
    for(@{$self->weapons})
    {
        return $_ if($_->type eq $type)
    }
    return undef;
}


sub description
{
    my $self = shift;
    my $desc = $self->name . " (" .  $self->type . "): HEALTH " . $self->health . " " . $self->aware_text . " "; 
    if(@{$self->status})
    {
        $desc .=  "[" . join(", ", @{$self->status}) . "]";
    }
    return $desc;
}

sub gain_action_point
{
    my $self = shift;
    $self->action_points($self->action_points + 1);
}
sub spend_action_point
{
    my $self = shift;
    $self->action_points($self->action_points - 1);
}


sub strategy
{
    my $self = shift;
    my $game = shift;
    return $self->_standard_ia($game, { 'close' => 'away',
                                        'near'  => 'away',
                                        'far'   => 'away' });
}

sub set_guard 
{
    my $self = shift;
    my $foe = shift;
    $self->activate_status('guard ' . $foe->tag);
}

around calculate_effects => sub 
{
    my $orig = shift;
    my $self = shift;
    my $game = shift;
    my $event = shift;
    my $data = shift;
    $self->$orig($game, $event, $data);
    if(my $guard = $self->has_status('guard'))
    {
        if($guard =~ /^guard (.*)$/)
        {
            my $guarded = $1;
            my $guarded_obj = undef;
            if($data->{subject_1}->game_type eq 'player'  &&
               $event =~ /^after/ && $event !~ /fly_away/ &&
               ($guarded_obj = grep { $_->tag eq $guarded } @{$data->{targets}}) )
            {
                $game->log($self->name . " guarding " . $guarded_obj->[0]->name . "! Action point given!");
                $self->gain_action_point();
            }
        }
    }

};

1;
