package Dancer::Serializer::JSONP;

use strict;
use warnings;
use Dancer::SharedData;
use parent 'Dancer::Serializer::JSON';

sub serialize {
    my $self = shift;
	
	my $callback = Dancer::SharedData->request->params('query')->{callback};
	
	my $json = $self->SUPER::serialize(@_);
	
	return $callback . '(' . $json . ');';
}

sub content_type {'application/javascript'}

1;
