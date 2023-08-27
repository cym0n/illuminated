package Illuminated::Weapon::Balthazar;

use v5.10;
use Moo;
extends 'Illuminated::Weapon';

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
 
  return $class->$orig({
        name => 'balthazar',
        type => 'rifle',
        try_type => 'mind',
        range => [ 'near' ],
        damage => 1
    });
};

sub calculate_effects
{
    my $self = shift;
    my $game = shift;
    my $event = shift;
    my $data = shift;
    if($event eq 'after attack')
    {
        #Dummy status for test purpose
        $game->log($self->name . " is smoking");
        $self->activate_status('smoking', 2);
    }
}

1;
