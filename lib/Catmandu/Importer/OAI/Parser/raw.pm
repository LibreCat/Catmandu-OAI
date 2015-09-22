package Catmandu::Importer::OAI::Parser::raw;

use Catmandu::Sane;
use Moo;

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    { _metadata => $dom->toString };
}

1;
