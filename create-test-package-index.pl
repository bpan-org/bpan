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
    my $version = $meta->{version} or die;

    $meta->{release}{url} = "https://github.com/$owner/$package.git";
    $meta->{release}{sha} = `(cd $dir; git rev-parse HEAD)`;
    chomp $meta->{release}{sha};

    $index{"$name/$owner/$version"} = $meta;
    $index{"$name/$owner"} = [$version];
    $index{"$name"} = "$name/$owner";

    if ($version eq '0.0.1') {
        $meta = Load Dump $meta;
        $meta->{version} = $version = '0.0.2';
        $index{"$name/$owner/$version"} = $meta;
        unshift @{$index{"$name/$owner"}}, $version;
    }
}

my $jxs = JSON::XS->new->ascii->pretty->allow_nonref->canonical;
print $jxs->encode(\%index);

