use 5.010_000;
use Dancer;
use Template;
use DBI;
use Math::Base36 ':all';
use File::Spec;
use File::Slurp;
use URI;

set 'database' => File::Spec->tmpdir() . '/shrinkr.db';
set 'template' => 'template_toolkit';
set 'logger' => 'console';
set 'log' => 'debug';
set 'show_errors' => 1;

layout 'main';

before_template sub {
    my $tokens = shift;

    $tokens->{'base'} = request->base();
    $tokens->{'css_url'} = 'css/style.css';
};

sub connect_db {
	my $dbh = DBI->connect("dbi:SQLite:dbname=".setting('database')) or
		die $DBI::errstr;

	return $dbh;
}

my $id = 0;
sub init_db {
    my $db = connect_db();

    my $sql = read_file("./schema.sql");
    $db->do($sql) or die $db->errstr;

    $sql = "SELECT MAX(id) FROM link";
    my $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute() or die $sth->errstr;
    ($id) = $sth->fetchrow_array() or die $sth->errstr;

}

sub get_next_id {
    return ++$id;
}

any ['get', 'post'] => '/' => sub {

    my $msg;
    my $err;

    if ( request->method() eq "POST" ) {
        my $uri = URI->new( params->{'url'} );

        if ( $uri->scheme !~ 'http' ) {
            $err = 'Error: Only HTTP or HTTPS URLs are accepted.';
        }
        else {

            my $nid = get_next_id();
            my $code = encode_base36($nid);

            my $sql = 'INSERT INTO link (id, code, url, count) VALUES (?, ?, ?, 0)';
            my $db = connect_db();
            my $sth = $db->prepare($sql) or die $db->errstr;
            $sth->execute( $nid, $code, $uri->canonical() ) or die $sth->errstr;
        
            $msg = $uri->as_string . " has been shrunk to " . 
                request->base() . $code;
       } 
    }

    template 'add.tt', {
        'err' => $err,
        'msg' => $msg,
    };

};

get qr|\A\/(?<code>[A-Za-z0-9]+)\Z| => sub {

    my $decode = decode_base36(uc captures->{'code'});

    if ( $decode > $id ) {
        send_error(404);
    }

    my $db = connect_db();
    my $sql = 'SELECT url, count FROM link WHERE id = ?';
    my $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute($decode) or die $sth->errstr;

    my ($url, $count) = $sth->fetchrow_array() or die $sth->errstr;

    $sql = 'UPDATE link SET count = ? WHERE id = ?';
    $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute(++$count, $decode);

    redirect $url;
};

get '/:code/stats' => sub {

    my $decode = decode_base36(uc params->{'code'});

    if ( $decode > $id ) {
        send_error(404);
    }

    my $sql = 'SELECT id, code, url, count FROM link WHERE id = ?';
    my $db = connect_db();
    my $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute($decode) or die $sth->errstr;

    my $prevl;
    my $nextl;

    unless ( ( $decode - 1 ) < 0 ) {
        $prevl = encode_base36( $decode - 1 );
    }

    unless ( ( $decode + 1 ) > $id ) {
        $nextl = encode_base36( $decode + 1 );
    }

    template 'stats.tt', {
        'stats' => $sth->fetchall_hashref('id'),
        'nextl' => $nextl,
        'prevl' => $prevl,
    };
};

get '/all_stats' => sub {

    my $sql = 'SELECT id, code, url, count FROM link';
    my $db = connect_db();
    my $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute() or die $sth->errstr;

    template 'stats.tt', {
        'stats' => $sth->fetchall_hashref('id'),
    };

};

init_db();
start;
