use Dancer;
use DBI;
use File::Spec;
use File::Slurp;
use Template;
use Dancer::Plugin::FlashMessage;

set 'database'     => File::Spec->tmpdir() . '/dancr.db';
set 'session'      => 'Simple';
set 'template'     => 'template_toolkit';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;
set 'username'     => 'admin';
set 'password'     => 'password';
set 'layout'       => 'main';

sub connect_db {
	my $dbh = DBI->connect("dbi:SQLite:dbname=".setting('database')) or
		die $DBI::errstr;

	return $dbh;
}

sub init_db {
	my $db = connect_db();
	my $schema = read_file('./schema.sql');
	$db->do($schema) or die $db->errstr;
}

before_template sub {
	my $tokens = shift;

	$tokens->{'css_url'} = request->base . 'css/style.css';
	$tokens->{'login_url'} = uri_for('/login');
	$tokens->{'logout_url'} = uri_for('/logout');
};

get '/' => sub {
	my $db = connect_db();
	my $sql = 'select id, title, text from entries order by id desc';
	my $sth = $db->prepare($sql) or die $db->errstr;
	$sth->execute or die $sth->errstr;
	template 'show_entries.tt', {
		'msg' => flash( 'message' ),
		'add_entry_url' => uri_for('/add'),
		'entries' => $sth->fetchall_hashref('id'),
	};
};

post '/add' => sub {
	if ( not session('logged_in') ) {
		send_error("Not logged in", 401);
	}

	my $db = connect_db();
	my $sql = 'insert into entries (title, text) values (?, ?)';
	my $sth = $db->prepare($sql) or die $db->errstr;
	$sth->execute(params->{'title'}, params->{'text'}) or die $sth->errstr;

	flash message => 'New entry posted!';
	redirect '/';
};

any ['get', 'post'] => '/login' => sub {
	my $err;

	if ( request->method() eq "POST" ) {
		# process form input
		if ( params->{'username'} ne setting('username') ) {
			$err = "Invalid username";
		}
		elsif ( params->{'password'} ne setting('password') ) {
			$err = "Invalid password";
		}
		else {
			session 'logged_in' => true;
			flash message => 'You are logged in.';
			return redirect '/';
		}
	}

	# display login form
	template 'login.tt', {
		'err' => $err,
	};

};

get '/logout' => sub {
	session->destroy;
	flash message => 'You are logged out.';
	redirect '/';
};

init_db();
start;

