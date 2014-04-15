#!/usr/bin/env perl

use strict;
use YAML::XS;
use JSON::XS;

my @packages = qw(
    bashplus
    git-hub
    json-bash
    test-more-bash
    test-tap-bash
);

my %index;

for my $package (@packages) {
    my $meta = YAML::XS::LoadFile "../../$package/Meta";
    my $name = $meta->{name} or die;
    $index{"ingydotnet/$name"} = $meta;
}

my $jxs = JSON::XS->new->ascii->pretty->allow_nonref;
print $jxs->encode(\%index);

