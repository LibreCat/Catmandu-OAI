package Catmandu::Importer::OAI::DC;

use Catmandu::Sane;
use Moo;

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    my $rec = {};

    for ($dom->findnodes("./*")) {
        my $name  = $_->localName;
        my $value = $_->textContent;
        push(@{$rec->{$name}}, $value);
    }

    $rec;
}

1;