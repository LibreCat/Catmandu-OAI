package Catmandu::Importer::OAI::Struct;

use Catmandu::Sane;
use Moo;
use XML::Struct qw(readXML);

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

	{ _metadata => readXML($dom) };
}

1;