use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Server;
use JSON::Client;
use JSON::Create 'create_json';
use boolean;
my $port = '9998';
my $response;
my $pid = fork ();
my $verbose;# = 1;
if ($pid) {
    my $sock = JSON::Client::make_sock ($port);
    ($response, undef) = JSON::Client::get ($sock, create_json ({}));
    $sock->close ();
    my $sock2 = JSON::Client::make_sock ($port);
    my ($stop, undef) = JSON::Client::get (
	$sock2, 
	create_json ({'JSON::Server::control' => 'stop'})
    );
    $sock2->close ();
    waitpid ($pid, 0);
}
else {
    my $server = JSON::Server->new (
	port => $port,
	handler => \&true_false,
	verbose => $verbose,
    );
    $server->serve ();
    exit;
}
like ($response, qr!"yes"\s*:\s*true!, "Got boolean true");
like ($response, qr!"no"\s*:\s*false!, "Got boolean false");
done_testing ();
exit;

sub true_false
{
    return {"yes" => true, "no" => false};
}
