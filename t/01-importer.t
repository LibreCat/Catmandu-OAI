#!/usr/bin/perl

use strict;
use warnings;
use Catmandu::Importer::OAI;
use Test::More;
use Data::Dumper;

my $importer = Catmandu::Importer::OAI->new(
    url => 'http://biblio.ugent.be/oai',
    set => "allFtxt"
);

my $record = $importer->first;

ok $record , 'listrecords';

$importer = Catmandu::Importer::OAI->new(
    url => 'http://biblio.ugent.be/oai',
    set => "allFtxt",
    dry => 1,
);

$record = $importer->first;

ok exists $record->{url} , 'dry run';

$importer = Catmandu::Importer::OAI->new(
    url => 'http://biblio.ugent.be/oai',
    set => "allFtxt",
    listIdentifiers => 1,
);

$record = $importer->first;

ok $record , 'listidentifiers';

done_testing 3;