package JSON::Server;
use warnings;
use strict;
use Carp;
use utf8;
our $VERSION = '0.00_08';

use IO::Socket;
use JSON::Create '0.30_04', ':all';
use JSON::Parse '0.60_01', ':all';

$SIG{PIPE} = sub {
    croak "Aborting on SIGPIPE";
};

sub set_opt
{
    my ($gs, $o, $nm) = @_;
    # Use exists here so that, e.g. verbose => $verbose, $verbose =
    # undef works OK.
    if (exists $o->{$nm}) {
	$gs->{$nm} = $o->{$nm};
	delete $o->{$nm};
    }
}

sub new
{
    my ($class, %o) = @_;
    my $gs = {};
    set_opt ($gs, \%o, 'verbose');
    set_opt ($gs, \%o, 'port');
    set_opt ($gs, \%o, 'handler');
    set_opt ($gs, \%o, 'data');
    for my $k (keys %o) {
	carp "Unknown option '$k'";
	delete $o{$k};
    }
    if (! $gs->{port}) {
	carp "No port specified";
    }
    $gs->{jc} = JSON::Create->new (
	indent => 1,
	sort => 1,
	downgrade_utf8 => 1,
    );
    $gs->{jc}->bool ('boolean');
    $gs->{jp} = JSON::Parse->new ();
    $gs->{jp}->upgrade_utf8 (1);
    return bless $gs;
}

sub so
{
    my %so = (
	Domain => IO::Socket::AF_INET,
	Proto => 'tcp',
	Type => IO::Socket::SOCK_STREAM,
    );
    # https://stackoverflow.com/a/2229946
    if (defined eval { SO_REUSEPORT }) {
	$so{ReusePort} = 1;
    }
    return %so;
}

sub serve
{
    my ($gs) = @_;
    my %so = so ();
    %so = (
	%so,
	Listen => 5,
	LocalPort => $gs->{port},
    );
    $gs->{server} = IO::Socket->new (%so);
    if (! $gs->{server}) {
	carp "Can't open socket: $@";
    }
    if ($gs->{verbose}) {
	vmsg ("Serving on $gs->{port}");
    }
    while (1) {
	my $got = '';
	my ($ok) = eval {
	    $gs->{client} = $gs->{server}->accept ();
	    if ($gs->{verbose}) {
		vmsg ("Got a message");
	    }
	    my $data;
	    my $max = 1000;
	    # It might be better to use the atmark method on $gs->{client}
	    # here.
	    while (! defined $data || length ($data) == $max) {
		$data = '';
		$gs->{client}->recv ($data, $max);
		$got .= $data;
	    }
	    1;
	};
	if (! $ok) {
	    carp "accept failed: $@";
	    next;
	}
	if ($gs->{verbose}) {
	    vmsg ("Received " . length ($got) . " bytes of data");
	}
	if (! valid_json ($got)) {
	    if ($gs->{verbose}) {
		vmsg ("Not valid json");
	    }
	    $gs->reply ({error => 'invalid JSON'});
	    next;
	}
	if ($gs->{verbose}) {
	    vmsg ("Validated as JSON");
	}
	my $input = $gs->{jp}->parse ($got);
	my $control = $input->{'JSON::Server::control'};
	if (defined $control) {
	    if ($control eq 'stop') {
		if ($gs->{verbose}) {
		    vmsg ("Received control message to stop");
		}
		$gs->reply ({'JSON::Server::response' => 'stopping'});
		if ($gs->{verbose}) {
		    vmsg ("Responded to control message to stop");
		}
		return;
	    }
	    warn "Unknown control command '$control'";
	}
	$gs->respond ($input);
    }
}

sub respond
{
    my ($gs, $input) = @_;
    my $reply;
    if (! $gs->{handler}) {
	carp "Handler is not set, will echo input back";
	$gs->{handler} = \&echo;
    }
    my $ok = eval {
	$reply = &{$gs->{handler}} ($gs->{data}, $input);
	1;
    };
    if (! $ok) {
	carp "Handler crashed: $@";
	$gs->reply ({error => "Handler crashed: $@"});
	return;
    }
    $gs->reply ($reply);
}

sub reply
{
    my ($gs, $msg) = @_;
    my $json_msg = $gs->{jc}->run ($msg);
    my $sent = $gs->{client}->send ($json_msg);
    if (! defined $sent) {
	warn "Error sending: $@\n";
    }
    $gs->{client}->close ();
}

# This is the default callback of the server.

sub echo
{
    my ($data, $input) = @_;
    return $input;
}

sub vmsg
{
    my ($msg) = @_;
    print __PACKAGE__ . ": $msg.\n";
}


1;
