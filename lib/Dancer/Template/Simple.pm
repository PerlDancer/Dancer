package Dancer::Template::Simple;
use strict;
use warnings;

use base 'Dancer::Template::Abstract';
Dancer::Template::Simple->attributes('start_tag', 'stop_tag');
use Dancer::FileUtils 'read_file_content';

sub init {
    my $self = shift;
    $self->start_tag('<%') unless defined $self->start_tag;
    $self->stop_tag('%>') unless defined $self->stop_tag;
}

sub render($$$) {
    my ($self, $template, $tokens) = @_;
    my $content;

    if (ref($template)) {
        $content = $$template;
    }
    else {
        die "'$template' is not a regular file"
            unless -f $template;
        $content = read_file_content($template);
        die "unable to read content for file $template" 
            if not defined $content;
    }

    $content = $self->interpolate($content, $tokens); 
    return $content;
}

sub interpolate {
    my ($self, $content, $tokens) = @_;
    my ($start, $stop) = ($self->start_tag, $self->stop_tag);
    
    while ($content =~ /${start}\s*(\S+)\s*${stop}/) {
        my $key = $1;
        my $value = _find_value_from_token_name($key, $tokens);
        $value    = _interpolate_value($value); 
        $content  =~ s/${start}\s*(\S+)\s*${stop}/$value/;
    }
    return $content;
}

# private

sub _find_value_from_token_name {
    my ($key, $tokens) = @_;
    my $value = undef;

    my @elements = split /\./, $key;
    foreach my $e (@elements) {
        if (not defined $value) {
            $value = $tokens->{$e};
        }
        elsif (ref($value) eq 'HASH') {
            $value = $value->{$e};
        }
        elsif (ref($value)) {
            local $@;
            eval { $value = $value->$e };
            $value = "" if $@;
        }
    }
    return $value;
}

sub _interpolate_value($) {
    my ($value) = @_;
    if (ref($value) eq 'CODE') {
        local $@;
        eval { $value = $value->() };
        $value = "" if $@;
    }
    elsif (ref($value) eq 'ARRAY') {
        $value = "@{$value}";
    }

    $value = "" if not defined $value;
    return $value;
}

1;

__END__

=pod

=head1 NAME

Dancer::Template::Simple - a pure Perl 5 template engine for Dancer

=head1 DESCRIPTION

This template engine is provided as a default one for the Dancer micro
framework.

This template engine should be fine for development purposes but is not a
powerful one, it's written in pure Perl and has no C bindings to accelerate the
template processing.

If you want to power an application with Dancer in production environment, it's
strongly advised to switch to Dancer::Template::TemplateToolkit.

=head1 SYNTAX

A template written for Dancer::Template::Simple should be working just fine with
Dancer::Template::TemplateToolkit. The opposite is not true though.

=over 4

=item B<variables>

To interpolate a variable in the template, use the following syntax:

    <% var1 %>

If 'var1' exists in the tokens hash given, its value will be written there.

=back

=head1 SEE ALSO

L<Dancer>, L<Dancer::Template>

=head1 AUTHOR

This module has been written by Alexis Sukrieh.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
