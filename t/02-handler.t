#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;
use Catmandu::Importer::OAI;
use Test::More;
use TestParser;
use Data::Dumper;

if ($ENV{RELEASE_TESTING}) {
	my $importer = Catmandu::Importer::OAI->new(
	    url => 'http://search.ugent.be/meercat/x/oai',
	    metadataPrefix => 'marcxml',
	    set => "eu",
	    handler => TestParser->new,
	);

	my $record = $importer->first;

	ok $record , 'listrecords';

	is $record->{test}, 'ok' , 'got correct data';
}

done_testing;