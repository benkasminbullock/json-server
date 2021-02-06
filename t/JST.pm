package JST;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT;
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
use warnings;
use strict;
use utf8;
use Carp;

use Test::More;
use JSON::Server;
use JSON::Client;
use JSON::Parse;
use JSON::Create;

push @EXPORT, (
    @Test::More::EXPORT,
    @JSON::Parse::EXPORT_OK,
    @JSON::Create::EXPORT_OK,
);

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

sub import
{
    strict->import ();
    utf8->import ();
    warnings->import ();

    Test::More->import ();
    JSON::Parse->import (':all');
    JSON::Create->import (':all');

    JST->export_to_level (1);
}

1;
