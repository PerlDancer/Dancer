package Dancer::Error;

use strict;
use warnings;

use Dancer::Response;
use Dancer::Renderer;
use Dancer::Config 'setting';
use Dancer::Logger;
use Dancer::Session;

sub new {
    my ($class, %params) = @_;
    my $self = \%params;
    bless $self, $class;

    $self->{title} ||= "Error " . $self->code;
    $self->{type}  ||= "runtime error";

    my $html_output = "<h2>" . $self->{type} . "</h2>";
    $html_output .= $self->backtrace;
    $html_output .= $self->environment;

    $self->{message} = $html_output;
    return $self;
}

sub code    { $_[0]->{code} }
sub title   { $_[0]->{title} }
sub message { $_[0]->{message} }

sub backtrace {
    my ($self) = @_;

    $self->{message} ||= "";
    my $message = "<pre class=\"error\">" . $self->{message} . "</pre>";

    # the default perl warning/error pattern
    my ($file, $line) = ($message =~ /at (\S+) line (\d+)/);

    # the Devel::SimpleTrace pattern
    ($file, $line) = ($message =~ /at.*\((\S+):(\d+)\)/)
      unless $file and $line;

    # no file/line found, cannot open a file for context
    return $message unless ($file and $line);

    # file and line are located, let's read the source Luke!
    my $fh;
    open $fh, '<', $file or return $message;
    my @lines = <$fh>;
    close $fh;


    my $backtrace = $message;

    $backtrace
      .= "<div class=\"title\">" . "$file around line $line" . "</div>";

    $backtrace .= "<pre class=\"content\">";

    $line--;
    my $start = (($line - 3) >= 0)             ? ($line - 3) : 0;
    my $stop  = (($line + 3) < scalar(@lines)) ? ($line + 3) : scalar(@lines);

    for (my $l = $start; $l <= $stop; $l++) {
        chomp $lines[$l];
        if ($l == $line) {
            $backtrace
              .= "<span class=\"nu\">"
              . tabulate($l + 1, $stop + 1)
              . "</span> <font color=\"red\">"
              . $lines[$l]
              . "</font>\n";
        }
        else {
            $backtrace
              .= "<span class=\"nu\">"
              . tabulate($l + 1, $stop + 1)
              . "</span> "
              . $lines[$l] . "\n";
        }
    }
    $backtrace .= "</pre>";


    return $backtrace;
}

sub tabulate {
    my ($number, $max) = @_;
    my $len = length($max);
    return $number if length($number) == $len;
    return " $number";
}

sub dumper {
    my $obj = shift;
    return "Unavailable without Data::Dumper"
        unless Dancer::ModuleLoader->load('Data::Dumper');


    # Take a copy of the data, so we can mask sensitive-looking stuff:
    my %data = %$obj;
    my $censored = _censor(\%data); 
   
    #use Data::Dumper;
    my $dd = Data::Dumper->new([\%data]);
    $dd->Terse(1)->Quotekeys(0)->Indent(1);
    my $content = $dd->Dump();
    $content =~ s{(\s*)(\S+)(\s*)=>}{$1<span class="key">$2</span>$3 =>}g;
    if ($censored) {
        $content .= "\n\nNote: Values of $censored sensitive-looking keys hidden\n";
    }
    return $content;
}

# Given a hashref, censor anything that looks sensitive.  Returns number of
# items which were "censored".
sub _censor {
    my $hash = shift;
    if (!$hash || ref $hash ne 'HASH') {
        warn "_censor given incorrect input: $hash";
        return;
    }
    my $censored = 0;
    for my $key (keys %$hash) {
        if (ref $hash->{$key} eq 'HASH') {
            $censored += _censor($hash->{$key});
        } elsif ($key =~ /(pass|card?num|pan|secret)/i) {
            $hash->{$key} = "Hidden (looks potentially sensitive)";
            $censored++;
        }
    }
    return $censored;
}

sub render {
    my $self = shift;
    return Dancer::Response->new(
        status  => $self->code,
        headers => ['Content-Type' => 'text/html'],
        content =>
          Dancer::Renderer->html_page($self->title, $self->message, 'error')
    ) if setting('show_errors');

    return Dancer::Renderer->render_error($self->code);
}

sub environment {
    my ($self) = @_;

    my $request = Dancer::SharedData->request;
    my $r_env = {};
    $r_env = $request->env if defined $request;

    my $env =
        "<div class=\"title\">Environment</div><pre class=\"content\">"
      . dumper($r_env)
      . "</pre>";
    my $settings =
        "<div class=\"title\">Settings</div><pre class=\"content\">"
      . dumper(Dancer::Config->settings)
      . "</pre>";
    my $source =
        "<div class=\"title\">Stack</div><pre class=\"content\">"
      . $self->get_caller
      . "</pre>";
    my $session = "";
    if (setting('session')) {
        $session = 
            qq[<div class="title">Session</div><pre class="content">]
            . dumper(  Dancer::Session->get  )
            . "</pre>";
    }
    return "$source $settings $session $env";
}

sub get_caller {
    my ($self) = @_;
    my @stack;

    my $deepness = 0;
    while (my ($package, $file, $line) = caller($deepness++)) {
        push @stack, "$package in $file l. $line";
    }

    return join("\n", reverse(@stack));
}

1;
