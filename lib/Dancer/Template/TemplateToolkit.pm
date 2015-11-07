package Dancer::Template::TemplateToolkit;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Template Toolkit wrapper for Dancer
$Dancer::Template::TemplateToolkit::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use Dancer::Config 'setting';
use Dancer::ModuleLoader;
use Dancer::Exception qw(:all);

use base 'Dancer::Template::Abstract';

my $_engine;

sub init {
    my ($self) = @_;

    my $class = $self->config->{subclass} || "Template";
    raise core_template => "$class is needed by Dancer::Template::TemplateToolkit"
      if !$class->can("process") and !Dancer::ModuleLoader->load($class);

    my $charset = setting('charset') || '';
    my @encoding = length($charset) ? ( ENCODING => $charset ) : ();

    my $is_subclass = $class ne 'Template';

    my @anycase  = $is_subclass ? () : ( ANYCASE  => 1 );
    my @absolute = $is_subclass ? () : ( ABSOLUTE => 1 );

    my @inc_path = $is_subclass ? ()
        : ( INCLUDE_PATH => $self->config->{INCLUDE_PATH} || setting('views') );

    my $start_tag = $is_subclass
        ? $self->config->{start_tag}
        : $self->config->{start_tag} || '<%';

    my $stop_tag = $is_subclass
        ? $self->config->{stop_tag} || $self->config->{end_tag}
        : $self->config->{stop_tag} || $self->config->{end_tag} || '%>';

    # TT expects quotemeta()'ed values here to be used as-is within
    # its regexp-based tokenizer. To support existing Dancer users who
    # prefer the default TT tags and who've already figured this out,
    # let's skip this if the tags are already ok.
    # Just FYI: TT hardcodes '\[%' and '%\]' as default.
    #
    my @start = ();
    if (defined $start_tag) {
        @start = ( START_TAG => $start_tag eq '\[%' || $start_tag eq '\[\%'
            ? $start_tag
            : quotemeta($start_tag)
        );
    }
    my @stop = ();
    if (defined $stop_tag) {
        @stop = ( END_TAG => $stop_tag eq '%\]' || $stop_tag eq '\%\]'
            ? $stop_tag
            : quotemeta($stop_tag)
        );
    }
    my @embedded = ();
    if ($self->config->{embedded_templates}) {
	Dancer::ModuleLoader->load('Template::Provider::FromDATA')
	    or croak "The Package Template::Provider::FromDATA must be installed to use embedded_templates";

	@embedded = ( LOAD_TEMPLATES => [Template::Provider::FromDATA->new()] );
    }

    my $tt_config = {
        @anycase,
        @absolute,
        @encoding,
        @inc_path,
        @start,
        @stop,
        @embedded,
        %{$self->config},
    };

    $_engine = $class->new(%$tt_config);
}

sub set_wrapper {
	my ($self, $when, $file) = @_;
	my $wrappers = $_engine->{SERVICE}->{WRAPPER};
	unless (defined $file) {
		$file = $when;
		my @orig = @$wrappers;
        $self->{orig_wrappers} = \@orig;
		@$wrappers = ($file);
        return;
	}
	if ($when eq 'outer') {
        unshift @$wrappers => $file;
    } elsif ($when eq 'inner') {
        push @$wrappers => $file;
    } else {
        raise core_template => "'$when' isn't a valid identifier";
    }
}

sub reset_wrapper {
    my ($self) = @_;
	my $wrappers = $_engine->{SERVICE}->{WRAPPER};
    my $orig = $self->{orig_wrappers} || [];
    my @old = @$wrappers;
    @$wrappers = @$orig;
    return @old;
}

sub unset_wrapper {
    my ($self, $when) = @_;
	my $wrappers = $_engine->{SERVICE}->{WRAPPER};
	if ($when eq 'outer') {
        return shift @$wrappers;
    } elsif ($when eq 'inner') {
        return pop @$wrappers;
    } else {
        raise core_template => "'$when' isn't a valid identifier";
    }
}

sub render {
    my ($self, $template, $tokens) = @_;

    $self->view_exists($template) or raise core_template => "'$template' doesn't exist or not a regular file";

    my $content = "";
    my $charset = setting('charset') || '';
    my @options = length($charset) ? ( binmode => ":encoding($charset)" ) : ();
    $_engine->process($template, $tokens, \$content, @options) or raise core_template => $_engine->error;
    return $content;
}

sub view_exists {
    my ($self, $view) = @_;

    return 1 if ref $view;

    if ($self->config->{embedded_templates}) {
	eval {
	    $_engine->context->template($view);
	};
	return ! $@;
    }

    return -f $view;
}

sub view {
    my ($self, $view) = @_;

    if ($self->config->{embedded_templates}) {
	return $view;
    }
    else {
	$self->SUPER::view($view);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Template::TemplateToolkit - Template Toolkit wrapper for Dancer

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Template> module.

This template engine is recommended for production purposes, but depends on the
Template module.

In order to use this engine, use the template setting:

    template: template_toolkit

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

Note that by default,  Dancer configures the Template::Toolkit engine to use
<% %> brackets instead of its default [% %] brackets.  This can be changed
within your config file - for example:

    template: template_toolkit
    engines:
        template_toolkit:
            start_tag: '[%'
            stop_tag: '%]'

You can also add any options you would normally add to the Template module's
initialization. You could, for instance, enable saving the compiled templates:

    engines:
        template_toolkit:
            COMPILE_DIR: 'caches/templates'
            COMPILE_EXT: '.ttc'

Note though that unless you change them, Dancer sets both of the Template
options C<ANYCASE> and C<ABSOLUTE> on, as well as pointing C<INCLUDE_PATH>
to your B<views> directory and setting C<ENCODING> to your B<charset>
setting.

=head1 SUBCLASSING

By default, L<Template> is used, but you can configure Dancer to use a
subclass of Template with the C<subclass> option.

    engines:
        template_toolkit:
            subclass: My::Template

When used like this, Dancer skips the defaults mentioned above.  Only those
included in your config file are sent to the subclass.

=head1 WRAPPER, META variables, SETs

Dancer already provides a WRAPPER-like ability, which we call a "layout". The
reason we do not use TT's WRAPPER (which also makes it incompatible with it) is
because not all template systems support it. Actually, most don't.

However, you might want to use it, and be able to define META variables and
regular L<Template::Toolkit> variables.

These few steps will get you there:

=over 4

=item * Disable the layout in Dancer

You can do this by simply commenting (or removing) the C<layout> configuration
in the F<config.yml> file.

=item * Use Template Toolkit template engine

Change the configuration of the template to Template Toolkit:

    # in config.yml
    template: "template_toolkit"

=item * Tell the Template Toolkit engine who's your wrapper

    # in config.yml
    # ...
    engines:
        template_toolkit:
            WRAPPER: layouts/main.tt

=back

Done! Everything will work fine out of the box, including variables and META
variables.

=head1 EMBEDDED TEMPLATES

You can embed your templates in your script file, to get a self-contained dancer
application in one file (inspired by L<http://advent.perldancer.org/2011/3>).

To enable this:

    # in app.pl
    # ...
    set engines => {
        template_toolkit => {
            embedded_templates => 1,
        },
    };
    set template => 'template_toolkit';

This feature requires L<Template::Provider::FromDATA>. Put your templates in the
__DATA__ section, and start every template with __${templatename}__.

=head1 USING TT'S WRAPPER STACK

This engine provides three additional methods to access the WRAPPER stack of
TemplateToolkit.

=head2 set_wrapper

Synopsis:

    engine('template')->set_wrapper( inner => 'inner_layout.tt' );
    engine('template')->set_wrapper( outer => 'outer_layout.tt' );
    engine('template')->set_wrapper( 'only_layout.tt' );

The first two lines pushes/unshifts layout files to the wrapper array.
The third line overwrites the wrapper array with a single element.

=head2 unset_wrapper

Synopsis:

    engine('template')->unset_wrapper('inner') # returns 'inner_layout.tt';
    engine('template')->unset_wrapper('outer') # returns 'outer_layout.tt';

These lines pops/shifts layout files from the wrapper array and returns the
removed elements.

=head2 reset_wrapper

Synopsis:

    engine('template')->reset_wrapper;

This method restores the wrapper array after a set_wrapper call.

=head1 SEE ALSO

L<Dancer>, L<Template>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
