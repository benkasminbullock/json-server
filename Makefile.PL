use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/JSON/Server.pm';
my $pod = 'lib/JSON/Server.pod';
my $github = 'github.com/benkasminbullock/json-server';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'JSON::Server',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
#	    homepage => 'http://',
        },
    },
    MIN_PERL_VERSION => '5.006001',
);
