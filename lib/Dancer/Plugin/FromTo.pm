package Dancer::Plugin::FromTo;

use Dancer ':syntax';
use Dancer::Plugin;

use Dancer::Serializer::JSON;
use Dancer::Serializer::YAML;
use Dancer::Serializer::XML;

Dancer::Serializer::JSON->init;
Dancer::Serializer::YAML->init;
Dancer::Serializer::XML->init;

register from_json => sub {
    Dancer::Serializer::JSON->deserialize(@_);
};

register to_json => sub {
    Dancer::Serializer::JSON->serialize(@_);
};

register from_yaml => sub {
    Dancer::Serializer::YAML->deserialize(@_);
};

register to_yaml => sub {
    Dancer::Serializer::YAML->serialize(@_);
};

register from_xml => sub {
    Dancer::Serializer::XML->deserialize(@_);
};

register to_xml => sub {
    Dancer::Serializer::XML->serialize(@_);
};

register_plugin;

1;
__END__

=head1 NAME

Dancer::Plugin::FromTo

=head1 SYNOPSIS

    use Dancer::Plugin::FromTo;

    my $data = to_json(params->{some_input});

=head1 DESCRIPTION

Import methods to serialize and deserialize data in your application.

=head2 METHODS

=over 4

=item B<from_json>

=item B<to_json>

=item B<from_yaml>

=item B<to_yaml>

=item B<from_xml>

=item B<to_xml>

=back



