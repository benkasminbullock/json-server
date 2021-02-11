# Make sure array references are OK

use FindBin '$Bin';
use lib "$Bin";
use JST;

my $in = [qw!monster baby!];
my $port = 9996;
my $pid = fork ();
my $rt; # round trip
if ($pid) {
    my $client = JSON::Client->new (port => $port);
    sleep (1);
    $rt = $client->send ($in);
    my $reply = $client->send ({'JSON::Server::control' => 'stop'});
    waitpid ($pid, 0);
}
else {
    my $server = JSON::Server->new (
	port => $port,
	handler => \&JSON::Server::echo,
    );
    $server->serve ();
    exit;
}
is_deeply ($rt, $in, "Sent an array reference");
done_testing ();
