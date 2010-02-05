diff --git a/lib/Dancer/Handler.pm b/lib/Dancer/Handler.pm
index d589cff..530a072 100644
--- a/lib/Dancer/Handler.pm
+++ b/lib/Dancer/Handler.pm
@@ -32,10 +32,6 @@ sub get_handler {
 sub handle_request {
     my ($self, $request) = @_;
 
-    # we may enter here with a CGI object in $request, but
-    # we don't want to remain like that after this point.
-    $request = Dancer::Request->normalize($request);
-
     # clean the request singleton first
     Dancer::SharedData->reset_all();
 
diff --git a/lib/Dancer/Renderer.pm b/lib/Dancer/Renderer.pm
index 814b6d3..fceb94b 100644
--- a/lib/Dancer/Renderer.pm
+++ b/lib/Dancer/Renderer.pm
@@ -83,7 +83,7 @@ sub html_page {
 sub get_action_response() {
     Dancer::Route->run_before_filters;
 
-    my $request = Dancer::SharedData->request || Dancer::Request->new;
+    my $request = Dancer::SharedData->request;
     my $path    = $request->path;
     my $method  = $request->method;
 
@@ -92,7 +92,7 @@ sub get_action_response() {
 }
 
 sub get_file_response() {
-    my $request     = Dancer::Request->new;
+    my $request     = Dancer::SharedData->request;
     my $path        = $request->path;
     my $static_file = path(setting('public'), $path);
     return Dancer::Renderer->get_file_response_for_path($static_file);
diff --git a/lib/Dancer/Request.pm b/lib/Dancer/Request.pm
index 48706bb..779caa0 100644
--- a/lib/Dancer/Request.pm
+++ b/lib/Dancer/Request.pm
@@ -28,17 +28,15 @@ Dancer::Request->attributes(
 sub new {
     my ($class, $env) = @_;
 
-    # init the ENV
     $env ||= {};
-    %ENV = (%ENV, %$env);
 
     my $self = {
         path           => undef,
         method         => undef,
         params         => {},
-        content_length => $ENV{CONTENT_LENGTH} || 0,
-        content_type   => $ENV{CONTENT_TYPE} || '',
-        _input         => undef,
+        content_length => $env->{CONTENT_LENGTH} || 0,
+        content_type   => $env->{CONTENT_TYPE} || '',
+        env            => $env,
         _chunk_size    => 4096,
         _raw_body      => '',
         _read_position => 0,
@@ -49,42 +47,25 @@ sub new {
     return $self;
 }
 
+sub env { $_[0]->{env} }
+
 # this is the way to ask for a hand-cooked request
 sub new_for_request {
     my ($class, $method, $path, $params) = @_;
     $params ||= {};
     $method = uc($method);
 
-    $ENV{PATH_INFO}      = $path;
-    $ENV{REQUEST_METHOD} = $method;
-
-    my $req = $class->new;
+    my $req = $class->new({ PATH_INFO => $path, REQUEST_METHOD => $method });
     $req->{params} = {%{$req->{params}}, %{$params}};
 
     return $req;
 }
 
-sub normalize {
-    my ($class, $request) = @_;
-    die "normalize() must be called as a class method"
-      if (ref $class);
-
-    my $req_class = ref($request);
-    return $request if $req_class eq $class;
-
-    if (($req_class eq 'CGI') || ($req_class eq 'CGI::PSGI')) {
-        return $class->new_for_request($request->request_method,
-            $request->path_info, scalar($request->Vars));
-    }
-
-    die "Invalid request, unable to process the query ($req_class)";
-}
-
 # public interface compat with CGI.pm objects
 sub request_method { method(@_) }
 sub path_info      { path(@_) }
 sub Vars           { params(@_) }
-sub input_handle   { shift->{_input} }
+sub input_handle   { $_[0]->{env}->{'psgi.input'} }
 
 sub params {
     my ($self, $name) = @_;
@@ -102,9 +83,6 @@ sub _init {
     $self->_build_method() unless $self->method;
     $self->_build_request_env();
 
-    # input for POST/PUT data are taken from PSGI if present,
-    # fallback to STDIN
-    $self->{_input} = $ENV{'psgi.input'} ? $ENV{'psgi.input'} : *STDIN;
     $self->{_http_body} =
       HTTP::Body->new($self->content_type, $self->content_length);
     $self->_build_params();
@@ -112,10 +90,10 @@ sub _init {
 
 sub _build_request_env {
     my ($self) = @_;
-    foreach my $http_env (grep /^HTTP_/, keys %ENV) {
+    foreach my $http_env (grep /^HTTP_/, keys %{$self->env}) {
         my $key = lc $http_env;
         $key =~ s/^http_//;
-        $self->{$key} = $ENV{$http_env};
+        $self->{$key} = $self->env->{$http_env};
     }
 }
 
@@ -135,15 +113,15 @@ sub _build_path {
     my ($self) = @_;
     my $path = "";
 
-    $path .= $ENV{'SCRIPT_NAME'}
-      if defined $ENV{'SCRIPT_NAME'};
-    $path .= $ENV{'PATH_INFO'}
-      if defined $ENV{'PATH_INFO'};
+    $path .= $self->env->{'SCRIPT_NAME'}
+      if defined $self->env->{'SCRIPT_NAME'};
+    $path .= $self->env->{'PATH_INFO'}
+      if defined $self->env->{'PATH_INFO'};
 
     # fallback to REQUEST_URI if nothing found
     # we have to decode it, according to PSGI specs.
-    $path ||= $self->_url_decode($ENV{REQUEST_URI})
-      if defined $ENV{REQUEST_URI};
+    $path ||= $self->_url_decode($self->env->{REQUEST_URI})
+      if defined $self->env->{REQUEST_URI};
 
     die "Cannot resolve path" if not $path;
     $self->{path} = $path;
@@ -151,7 +129,7 @@ sub _build_path {
 
 sub _build_method {
     my ($self) = @_;
-    $self->{method} = $ENV{REQUEST_METHOD}
+    $self->{method} = $self->env->{REQUEST_METHOD}
       || $self->{request}->request_method();
 }
 
@@ -165,7 +143,7 @@ sub _url_decode {
 
 sub _parse_get_params {
     my ($self, $r_params) = @_;
-    $self->_parse_params($r_params, $ENV{QUERY_STRING});
+    $self->_parse_params($r_params, $self->env->{QUERY_STRING});
 }
 
 sub _parse_post_params {
@@ -227,7 +205,7 @@ sub _has_something_to_read {
 # taken from Miyagawa's Plack::Request::BodyParser
 sub _read {
     my ($self,)   = @_;
-    my $remaining = $ENV{CONTENT_LENGTH} - $self->{_read_position};
+    my $remaining = $self->env->{CONTENT_LENGTH} - $self->{_read_position};
     my $maxlength = $self->{_chunk_size};
 
     return if ($remaining <= 0);
