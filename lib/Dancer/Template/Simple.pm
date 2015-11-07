package Dancer::Template::Simple;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: pure Perl 5 template engine for Dancer
$Dancer::Template::Simple::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use base 'Dancer::Template::Abstract';
Dancer::Template::Simple->attributes('start_tag', 'stop_tag');
use Dancer::FileUtils 'read_file_content';
use Dancer::Exception qw(:all);

sub init {
    my $self     = shift;
    my $settings = $self->config;

    my $start = $settings->{'start_tag'} || '<%';
    my $stop  = $settings->{'stop_tag'}  || '%>';

    $self->start_tag($start) unless defined $self->start_tag;
    $self->stop_tag($stop)   unless defined $self->stop_tag;
}

sub render {
    my ($self, $template, $tokens) = @_;
    my $content;

    $content = _read_content_from_template($template);
    $content = $self->parse_branches($content, $tokens);

    return $content;
}

sub parse_branches {
    my ($self, $content, $tokens) = @_;
    my ($start, $stop) = ($self->start_tag, $self->stop_tag);

    my @buffer;
    my $prefix             = "";
    my $should_bufferize   = 1;
    my $bufferize_if_token = 0;

#    $content =~ s/\Q${start}\E(\S)/${start} $1/sg;
#    $content =~ s/(\S)\Q${stop}\E/$1 ${stop}/sg;

    # we get here a list of tokens without the start/stop tags
    my @full = split(/\Q$start\E\s*(.*?)\s*\Q$stop\E/, $content);

    # and here a list of tokens without variables
    my @flat = split(/\Q$start\E\s*.*?\s*\Q$stop\E/, $content);

    # eg: for 'foo=<% var %>'
    #   @full = ('foo=', 'var')
    #   @flat = ('foo=')

    my $flat_index = 0;
    my $full_index = 0;
    for my $word (@full) {

        # flat word, nothing to do
        if (defined $flat[$flat_index]
            && ($flat[$flat_index] eq $full[$full_index]))
        {
            push @buffer, $word if $should_bufferize;
            $flat_index++;
            $full_index++;
            next;
        }

        my @to_parse = ($word);
        @to_parse = split(/\s+/, $word) if $word =~ /\s+/;

        for my $w (@to_parse) {

            if ($w eq 'if') {
                $bufferize_if_token = 1;
            }
            elsif ($w eq 'else') {
                $should_bufferize = !$should_bufferize;
            }
            elsif ($w eq 'end') {
                $should_bufferize = 1;
            }
            elsif ($bufferize_if_token) {
                my $bool = _find_value_from_token_name($w, $tokens);
                $should_bufferize = _interpolate_value($bool) ? 1 : 0;
                $bufferize_if_token = 0;
            }
            elsif ($should_bufferize) {
                my $val =
                  _interpolate_value(_find_value_from_token_name($w, $tokens));
                push @buffer, $val;
            }
        }

        $full_index++;
    }

    return join "", @buffer;
}

# private

sub _read_content_from_template {
    my ($template) = @_;
    my $content = undef;

    if (ref($template)) {
        $content = $$template;
    }
    else {
        raise core_template => "'$template' is not a regular file"
          unless -f $template;
        $content = read_file_content($template);
        raise core_template => "unable to read content for file $template"
          if not defined $content;
    }
    return $content;
}

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

sub _interpolate_value {
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

=encoding UTF-8

=head1 NAME

Dancer::Template::Simple - pure Perl 5 template engine for Dancer

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This template engine is provided as a default one for the L<< Dancer >> micro
framework.

This template engine should be fine for development purposes but is not a
powerful one, it's written in pure Perl and has no C bindings to accelerate the
template processing.

If you want to power an application with Dancer in production environment, it's
strongly advised to switch to L<< Dancer::Template::TemplateToolkit >>.

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

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
