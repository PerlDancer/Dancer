package Dancer::Route;

use strict;
use warnings;
use Carp;
use base 'Dancer::Object';

use Dancer::App;
use Dancer::Logger;
use Dancer::Config 'setting';
use Dancer::Request;
use Dancer::Response;

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

# supported options and aliases
my @_supported_options = Dancer::Request->get_attributes();
my %_options_aliases = (agent => 'user_agent');

sub init {
    my ($self) = @_;
    $self->{'_compiled_regexp'} = undef;

    if (!$self->pattern) {
        croak "cannot create Dancer::Route without a pattern";
    }

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
    my %params;

    Dancer::Logger::core("trying to match `$path' "
          . "against /"
          . $self->{_compiled_regexp}
          . "/");

    my @values = $path =~ $self->{_compiled_regexp};
    Dancer::Logger::core("  --> got @values") if @values;

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

    # named tokens
    my @tokens = @{$self->{_params} || []};

    Dancer::Logger::core("  --> named tokens are: @tokens") if @tokens;
    if (@tokens) {
        for (my $i = 0; $i < @tokens; $i++) {
            $params{$tokens[$i]} = $values[$i];
        }
        return $self->save_match_data($request, \%params);
    }

    elsif ($self->{_should_capture}) {
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
        croak "Not a valid option for route matching: `$opt'"
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

    my $content  = $self->execute();
    my $response = Dancer::Response->current;

    if ($response->{pass}) {

        if ($self->next) {
            my $next_route = $self->find_next_matching_route($request);
            return $next_route->run($request);
        }
        else {
            croak "Last matching route passed";
        }
    }

    # coerce undef content to empty string to
    # prevent warnings
    $content = (defined $content) ? $content : '';

    # drop content if HEAD request
    $content = '' if $request->is_head;

    # init response headers
    my $ct = $response->{content_type} || setting('content_type');
    my $st = $response->{status}       || 200;
    my $headers = [];
    push @$headers, @{$response->headers_to_array};

    # content type may have already be set earlier
    # (eg: with send_error)
    push(@$headers, 'Content-Type' => $ct)
      unless grep {/Content-Type/} @$headers;

    return $content if ref($content) eq 'Dancer::Response';
    return Dancer::Response->new(
        status       => $st,
        headers      => $headers,
        content      => $content,
        content_type => $ct,
    );
}

sub find_next_matching_route {
    my ($self, $request) = @_;
    my $next = $self->next;
    return unless $next;

    return $next if $next->match($request);
    return $next->find_next_matching_route($request);
}

sub execute {
    my ($self) = @_;

    if (Dancer::Config::setting('warnings')) {
        my $warning;
        local $SIG{__WARN__} = sub { $warning = $_[0] };
        my $content = $self->code->();
        if ($warning) {
            return Dancer::Error->new(
                status  => 500,
                message => "Warning caught during route execution: $warning",
            )->render;
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
        my $regexp = $self->regexp || $self->pattern;
        if ($regexp !~ /^$prefix/) {
            $self->{pattern} = qr{${prefix}${regexp}};
        }
    }
    elsif ($self->pattern eq '/') {

        # if pattern is '/', we should match:
        # - /prefix/
        # - /prefix
        # this is done by creating a regex for this case
        my $pattern = $self->pattern;
        my $regex   = qr/$prefix(?:$pattern)?$/;
        $self->{regexp}  = $regex;
        $self->{pattern} = $regex;
    }
    else {
        $self->{pattern} = $prefix . $self->pattern;
        $self->{pattern} =~ s/\/$//;
    }

    return $prefix;
}

sub equals {
    my ($self, $route) = @_;

    # TODO remove this hack when r() is deprecated
    my $r1 = $self->regexp  || $self->pattern;
    my $r2 = $route->regexp || $route->pattern;
    return $r1 eq $r2;
}

sub is_regexp {
    my ($self) = @_;
    return ($self->pattern && (ref($self->pattern) eq 'Regexp'))
      || $self->regexp;
}

sub _build_regexp {
    my ($self) = @_;

    if ($self->is_regexp) {
        $self->{_compiled_regexp} = $self->regexp || $self->pattern;
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
        @params = $pattern =~ /:([^\/\.]+)/g;
        if (@params) {
            $pattern =~ s/(:[^\/\.]+)/\(\[\^\/\]\+\)/g;
            $capture = 1;
        }
    }

    # parse wildcards
    if ($pattern =~ /\*/) {
        $pattern =~ s/\*/\(\[\^\/\]\+\)/g;
        $capture = 1;
    }

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
