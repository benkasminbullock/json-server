# Test that our tests don't use the same port.

# Use of the same port numbers led to test failures on sophisticated
# systems.

# http://www.cpantesters.org/cpan/report/5cceb166-6d3a-11eb-9f75-d8046d6b008a

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use File::Slurper 'read_text';
my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

my $dir = "$Bin/../t/";
my @tests = <$dir/*.t>;
my %ports;
for my $test (@tests) {
    my $text = read_text ($test);
    my $found;
    if ($text =~ m!\$port\s*=\s*['"]?([0-9]+)['"]?!) {
	my $port = $1;
	ok (! $ports{$port}, "Port $port is not used by another file");
	$ports{$port} = 1;
	$found = 1;
    }
    ok ($found, "Found a port in $test");
}

done_testing ();
