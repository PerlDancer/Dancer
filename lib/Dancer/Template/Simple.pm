package Dancer::Template::Simple;
use strict;
use warnings;

use base 'Dancer::Template::Abstract';
Dancer::Template::Simple->attributes('start_tag', 'stop_tag');
use Dancer::FileUtils 'read_file_content';

sub init {
    my $self = shift;
    $self->start_tag('<%') unless defined $self->start_tag;
    $self->stop_tag('%>')  unless defined $self->stop_tag;
}

sub render($$$) {
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
    my $opened_tag         = 0;
    my $bufferize_if_token = 0;
    $content =~ s/\Q${start}\E(\S)/${start} $1/sg;
    $content =~ s/(\S)\Q${stop}\E/$1 ${stop}/sg;

    foreach my $word (split / /, $content) {
        if ($word =~ /(.*)\Q$start\E/s) {
            my $junk = $1;
            $opened_tag = 1;
            if (defined($junk) && length($junk)) {
                $prefix = $junk;
            }
        }
        elsif ($word =~ /\Q$stop\E(.*)/s) {
            my $junk = $1;
            if (defined($junk) && length($junk)) {
                if (@buffer) {
                    $buffer[$#buffer] .= $junk;
                }
                else {
                    push @buffer, $junk;
                }
            }
            $opened_tag = 0;
        }
        elsif ($word eq 'if' && $opened_tag) {
            $bufferize_if_token = 1;
            next;
        }
        elsif ($word eq 'else' && $opened_tag) {
            $should_bufferize = !$should_bufferize;
            next;
        }
        elsif ($word eq 'end' && $opened_tag) {
            $should_bufferize = 1;
        }
        elsif ($bufferize_if_token) {
            my $bool = _find_value_from_token_name($word, $tokens);
            $should_bufferize = _interpolate_value($bool) ? 1 : 0;
            $bufferize_if_token = 0;
            next;
        }
        elsif ($opened_tag) {
            push @buffer,
              ( $prefix
                  . _interpolate_value(
                    _find_value_from_token_name($word, $tokens)
                  )
              );
            $prefix = "";
        }
        elsif ($should_bufferize) {
            push @buffer, $prefix . $word;
            $prefix = "";
        }
    }

    return join " ", @buffer;
}

# private

sub _read_content_from_template {
    my ($template) = @_;
    my $content = undef;

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
