package Catmandu::Store::OAI::Bag;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Carp qw(confess);
use Catmandu::Hits;
use Catmandu::Error;
use Moo;

our $VERSION = '0.17';

with 'Catmandu::Bag';

sub generator {
    my ($self)    = @_;
    my $oai = $self->store->oai;
    my $set = $self->name eq 'data' ? undef : $self->name;

    $oai->_list_records({
        set => $set,
        metadataPrefix => $oai->metadataPrefix
    });
}

sub count {
    my ($self)    = @_;
    confess "Not implemented";
}

sub get {
    my ($self, $id) = @_;
    my $set = $self->name eq 'data' ? undef : $self->name;

    my $oai = $self->store->oai;

    my $rec = $oai->_get_record({
        identifier     => $id ,
        metadataPrefix => $oai->metadataPrefix
    })->();

    if ($set) {
        my $sets = $rec->{_setSpec} // [];
        if (grep(/^$set$/,@$sets)) {
            return $rec;
        }
        else {
            return undef;
        }
    }
    else {
        return $rec;
    }
}

sub add {
    my ($self, $data) = @_;
    confess "OAI is a read-only store";
}

sub delete {
    my ($self, $id) = @_;
    confess "OAI is a read-only store";
}

sub delete_all {
    my ($self)    = @_;
    confess "OAI is a read-only store";
}

sub commit {
    1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::OAI::Bag - Catmandu::Bag implementation for OAI-PMH

=head1 DESCRIPTION

This class isn't normally used directly. Instances are constructed using the store's C<bag> method.

=head1 SEE ALSO

L<Catmandu::Bag>

=cut
