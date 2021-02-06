#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use lib "$Bin/copied/lib";
use Perl::Build;

my %build = (
    make_pod => "$Bin/make-pod.pl",
);

if ($ENV{CI}) {
    delete $build{c};
    $build{verbose} = 1;
    $build{no_make_examples} = 1;
}

perl_build (%build);
exit;
