package JSON::Client;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
use warnings;
use strict;
use utf8;
use Carp;
use JSON::Parse 'valid_json';
use JSON::Create;
use Unicode::UTF8 'decode_utf8';

sub new
{
    my ($class, %options) = @_;
    my $port = $options{port};
    if (! $port) {
	carp "No port specified";
	return undef;
    }
    delete $options{port};
    my $verbose = $options{verbose};
    if ($verbose) {
	print __PACKAGE__ . "->new - messages on.\n";
    }
    delete $options{verbose};
    for my $k (keys %options) {
	carp "Unknown option '$k'";
	delete $options{$k};
    }
    my $client = bless {
	port => $port,
	verbose => $verbose,
	jc => JSON::Create->new (downgrade_utf8 => 1,),
	jp => JSON::Parse->new (),
    };
    return $client;
}

sub JSON::Client::send
{
    my ($jcl, $input) = @_;
    if (! $input) {
	carp "Nothing to send";
	return;
    }
    my $json_msg = $jcl->{jc}->create ($input);
    my $sock = IO::Socket->new (
	Domain => IO::Socket::AF_INET,
	PeerPort => $jcl->{port},
	PeerHost => 'localhost',
	Proto => 'tcp',
	Type => IO::Socket::SOCK_STREAM,
    );
    if (! $sock) {
	print "$!\n";
	return;
    }
    if ($jcl->{verbose}) {
	print __PACKAGE__ . "::send - sending $json_msg\n";
    }
    $sock->send ($json_msg);
    my $got = '';
    my ($ok) = eval {
	my $data;
	my $max = 1000;
	while (! defined $data || length ($data) == $max) {
	    $data = '';
	    $sock->recv ($data, $max);
	    $got .= $data;
	}
	1;
    };
    $sock->close ();
    if (! $ok) {
	carp "Error reading from server: $@";
	return {error => "Error reading from server: $@"};
    }
    if ($jcl->{verbose}) {
	print __PACKAGE__ . "::send - got reply '$got'\n";
    }
    $got = decode_utf8 ($got);
    if (! valid_json ($got)) {
	if ($jcl->{verbose}) {
	    print __PACKAGE__ . "::send - not valid JSON\n";
	}
	return {error => 'invalid JSON'};
    }
    return $jcl->{jp}->parse ($got);
}

1;
