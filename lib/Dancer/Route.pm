package Dancer::Route;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Class to represent a route in Dancer
$Dancer::Route::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use base 'Dancer::Object';

use Dancer::App;
use Dancer::Logger;
use Dancer::Config 'setting';
use Dancer::Request;
use Dancer::Response;
use Dancer::Exception qw(:all);
use Dancer::Factory::Hook;

Dancer::Route->attributes(
    qw(
      app
      method
      pattern
      prefix
      code
      prev
      regexp
      next
      options
      match_data
      )
);

Dancer::Factory::Hook->instance->install_hooks(
    qw/on_route_exception/
);

# supported options and aliases
my @_supported_options = Dancer::Request->get_attributes();
my %_options_aliases = (agent => 'user_agent');

sub init {
    my ($self) = @_;
    $self->{'_compiled_regexp'} = undef;

    raise core_route => "cannot create Dancer::Route without a pattern"
        unless defined $self->pattern;

    # If the route is a Regexp, store it directly
    $self->regexp($self->pattern) 
      if ref($self->pattern) eq 'Regexp';

    $self->check_options();
    $self->app(Dancer::App->current);
    $self->prefix(Dancer::App->current->prefix) if not $self->prefix;
    $self->_init_prefix() if $self->prefix;
    $self->_build_regexp();
    $self->set_previous($self->prev) if $self->prev;

    return $self;
}

sub set_previous {
    my ($self, $prev) = @_;
    $self->prev($prev);
    $self->prev->{'next'} = $self;
    return $prev;
}

sub save_match_data {
    my ($self, $request, $match_data) = @_;
    $self->match_data($match_data);
    $request->_set_route_params($match_data);

    return $match_data;
}

# Does the route match the request
sub match {
    my ($self, $request) = @_;

    my $method = lc($request->method);
    my $path   = $request->path_info;

    Dancer::Logger::core(
        sprintf "Trying to match '%s %s' against /%s/ (generated from '%s')",
            $request->method, $path, $self->{_compiled_regexp}, $self->pattern
    );

    my @values = $path =~ $self->{_compiled_regexp};

    Dancer::Logger::core("  --> got ".
        map { defined $_ ? $_ : 'undef' } @values)
        if @values;

    # if some named captures found, return captures
    # no warnings is for perl < 5.10
    if (my %captures =
        do { no warnings; %+ }
      )
    {
        Dancer::Logger::core(
            "  --> captures are: " . join(", ", keys(%captures)))
          if keys %captures;
        return $self->save_match_data($request, {captures => \%captures});
    }

    return unless @values;

    # save the route pattern that matched
    # TODO : as soon as we have proper Dancer::Internal, we should remove
    # that, it's just a quick hack for plugins to access the matching
    # pattern.
    # NOTE: YOU SHOULD NOT USE THAT, OR IF YOU DO, YOU MUST KNOW
    # IT WILL MOVE VERY SOON
    $request->{_route_pattern} = $self->pattern;

    # regex comments are how we know if we captured a token,
    # splat or a megasplat
    my @token_or_splat
        = $self->{_compiled_regexp} =~ /\(\?#([token|(?:mega)?splat]+)\)/g;
    if (@token_or_splat) {
        # named tokens
        my @tokens = @{$self->{_params} || []};
        Dancer::Logger::core("  --> named tokens are: @tokens") if @tokens;

        my %params;
        my @splat;
        for ( my $i = 0; $i < @values; $i++ ) {
            # Is this value from a token?
            if ( $token_or_splat[$i] eq 'token' ) {
                $params{ shift @tokens } = $values[$i];
                next;
            }

            # megasplat values are split on '/'
            if ($token_or_splat[$i] eq 'megasplat') {
                $values[$i] = [ split '/' => $values[$i] ];
            }
            push @splat, $values[$i];
        }
        return $self->save_match_data( $request, {
            %params,
            ( @splat ? ( splat => \@splat ) : () ),
        });
    }

    if ($self->{_should_capture}) {
        return $self->save_match_data($request, {splat => \@values});
    }

    return $self->save_match_data($request, {});
}

sub has_options {
    my ($self) = @_;
    return keys(%{$self->options}) ? 1 : 0;
}

sub check_options {
    my ($self) = @_;
    return 1 unless defined $self->options;

    for my $opt (keys %{$self->options}) {
        raise core_route => "Not a valid option for route matching: `$opt'"
          if not(    (grep {/^$opt$/} @{$_supported_options[0]})
                  || (grep {/^$opt$/} keys(%_options_aliases)));
    }
    return 1;
}

sub validate_options {
    my ($self, $request) = @_;

    while (my ($option, $value) = each %{$self->options}) {
        $option = $_options_aliases{$option}
          if exists $_options_aliases{$option};
        return 0 if (not $request->$option) || ($request->$option !~ $value);
    }
    return 1;
}

sub run {
    my ($self, $request) = @_;

    my $content = try {
        $self->execute();
    } continuation {
        my ($continuation) = @_;
        # route related continuation
        $continuation->isa('Dancer::Continuation::Route')
          or $continuation->rethrow();
        # If the continuation carries some content, get it
        my $content = $continuation->return_value();
        defined $content or return; # to avoid returning undef;
        return $content;
    } catch {
        my ($exception) = @_;
        Dancer::Factory::Hook->execute_hooks('on_route_exception', $exception);
        die $exception;
    };
    my $response = Dancer::SharedData->response;

    if ( $response && $response->is_forwarded ) {
        my $new_req =
            Dancer::Request->forward($request, $response->{forward});
        my $marshalled = Dancer::Handler->handle_request($new_req);

        return Dancer::Response->new(
            encoded => 1,
            status  => $marshalled->[0],
            headers => $marshalled->[1],
            # if the forward failed with 404, marshalled->[2] is not an array, but a GLOB
            content => ref($marshalled->[2]) eq "ARRAY" ? @{ $marshalled->[2] } : $marshalled->[2]
        );
    }

    if ($response && $response->has_passed) {
        $response->pass(0);

        # find the next matching route and run it
        while ($self = $self->next) {
            return $self->run($request) if $self->match($request);
        }

        Dancer::Logger::core('Last matching route passed!');
        return Dancer::Renderer->render_error(404);
    }

    # coerce undef content to empty string to
    # prevent warnings
    $content = (defined $content) ? $content : '';

    my $ct =
      ( defined $response && defined $response->content_type )
      ? $response->content_type()
      : setting('content_type');

    my $st = defined $response ? $response->status : 200;

    my $headers = [];
    push @$headers, @{ $response->headers_to_array } if defined $response;

    # content type may have already be set earlier
    # (eg: with send_error)
    push(@$headers, 'Content-Type' => $ct)
      unless grep {/Content-Type/} @$headers;

    return $content if ref($content) eq 'Dancer::Response';
    return Dancer::Response->new(
        status       => $st,
        headers      => $headers,
        content      => $content,
    );
}

sub execute {
    my ($self) = @_;

    if (Dancer::Config::setting('warnings')) {
        my $warning;
        my $content = do {
            local $SIG{__WARN__} = sub { $warning ||= $_[0] };
            $self->code->();
        };
        if ($warning) {
            die "Warning caught during route execution: $warning";
        }
        return $content;
    }
    else {
        return $self->code->();
    }
}

sub _init_prefix {
    my ($self) = @_;
    my $prefix = $self->prefix;

    if ($self->is_regexp) {
        my $regexp = $self->regexp;
        if ($regexp !~ /^$prefix/) {
            $self->regexp(qr{${prefix}${regexp}});
        }
    }
    elsif ($self->pattern eq '/') {

        # if pattern is '/', we should match:
        # - /prefix/
        # - /prefix
        # this is done by creating a regex for this case
        my $qpattern = quotemeta( $self->pattern );
        my $qprefix  = quotemeta( $self->prefix );
        my $regex    = qr/^$qprefix(?:$qpattern)?$/;
        $self->{regexp}  = $regex;
        $self->{pattern} = $regex;
    }
    else {
        $self->{pattern} = $prefix . $self->pattern;
    }

    return $prefix;
}

sub equals {
    my ($self, $route) = @_;
    return $self->regexp eq $route->regexp;
}

sub is_regexp {
    my ($self) = @_;
    return defined $self->regexp;
}

sub _build_regexp {
    my ($self) = @_;

    if ($self->is_regexp) {
        $self->{_compiled_regexp} = $self->regexp;
        $self->{_compiled_regexp} = qr/^$self->{_compiled_regexp}$/;
        $self->{_should_capture} = 1;
    }
    else {
        $self->_build_regexp_from_string($self->pattern);
    }

    return $self->{_compiled_regexp};
}

sub _build_regexp_from_string {
    my ($self, $pattern) = @_;
    my $capture = 0;
    my @params;

    # look for route with params (/hello/:foo)
    if ($pattern =~ /:/) {
        @params = $pattern =~ /:([^\/\.\?]+)/g;
        if (@params) {
            $pattern =~ s!(:[^\/\.\?]+)!(?#token)([^/]+)!g;
            $capture = 1;
        }
    }

    # parse megasplat
    # we use {0,} instead of '*' not to fall in the splat rule
    # same logic for [^\n] instead of '.'
    $capture = 1 if $pattern =~ s!\Q**\E!(?#megasplat)([^\n]+)!g;

    # parse wildcards
    $capture = 1 if $pattern =~ s!\*!(?#splat)([^/]+)!g;

    # escape dots
    $pattern =~ s/\./\\\./g if $pattern =~ /\./;

    # escape slashes
    $pattern =~ s/\//\\\//g;

    $self->{_compiled_regexp} = "^${pattern}\$";
    $self->{_params}          = \@params;
    $self->{_should_capture}  = $capture;

    return $self->{_compiled_regexp};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Route - Class to represent a route in Dancer

=head1 VERSION

version 1.3202

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
