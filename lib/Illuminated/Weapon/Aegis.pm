package Illuminated::Weapon::Aegis;

use v5.10;
use Moo;
extends 'Illuminated::Weapon';

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
 
  return $class->$orig({
    name => 'aegis',
    type => 'shield',
    try_type => 'power',
    range => [ ],
    damage => 0
  });
};

sub calculate_effects
{
    my $self = shift;
    my $game = shift;
    my $event = shift;
    my $data = shift;
    
    if($event eq 'before parry')
    {
        $data->{subject_1}->activate_status('parry');
    }
}

1;
