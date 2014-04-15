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
my $owner = "ingydotnet";

for my $package (@packages) {
    my $dir = "../$package";
    my $meta = YAML::XS::LoadFile "$dir/Meta";
    my $name = $meta->{name} or die;

    $meta->{release}{url} = "http://github.com/$owner/$name.git";
    $meta->{release}{sha} = `(cd $dir; git rev-parse HEAD)`;

    $index{"$owner/$name"} = $meta;
    $index{"$name"} = "$owner/$name";
}

my $jxs = JSON::XS->new->ascii->pretty->allow_nonref->canonical;
print $jxs->encode(\%index);

