use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

plan tests => 1;

pod_coverage_ok(
    "Dancer2::Plugin::Passphrase",
    "Dancer2::Plugin::Passphrase has full POD coverage"
);
