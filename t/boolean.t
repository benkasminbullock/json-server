use FindBin '$Bin';
use lib "$Bin";
use JST;

use boolean;
my $port = '9998';
my $response;
my $pid = fork ();
my $verbose;# = 1;
if ($pid) {
    # Give the server some time to start.
    sleep (1);
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
