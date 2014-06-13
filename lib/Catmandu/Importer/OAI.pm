package Catmandu::Importer::OAI::DC;

use Catmandu::Sane;
use Moo;

has metadataPrefix => (is => 'ro' , default => sub { "oai_dc" });

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

package Catmandu::Importer::OAI;

use Catmandu::Sane;
use Moo;
use HTTP::OAI;
use Data::Dumper;

with 'Catmandu::Importer';

has url     => (is => 'ro', required => 1);
has metadataPrefix => (is => 'ro' , default => sub { "oai_dc" });
has handler => (is => 'ro', default => sub { Catmandu::Importer::OAI::DC->new });
has set     => (is => 'ro');
has from    => (is => 'ro');
has until   => (is => 'ro');
has oai     => (is => 'ro', lazy => 1, builder => '_build_oai');
has dry     => ( is => 'ro' );

sub _build_oai {
    my ($self) = @_;
    HTTP::OAI::Harvester->new(baseURL => $_[0]->url, resume => 1);
}

sub _map_record {
    my ($self, $rec) = @_;

    my $sets       = [ $rec->header->setSpec ];
    my $identifier = $rec->identifier;
    my $datestamp  = $rec->datestamp;
    my $status     = $rec->status // "";
    my $dom        = $rec->metadata ? $rec->metadata->dom->nonBlankChildNodes->[0]->nonBlankChildNodes->[0] : undef;
    my $metadata   = $dom ? $dom->toString : "";
    my $about      = [];

    for ($rec->about) {
        push(@$about , $_->dom->nonBlankChildNodes->[0]->nonBlankChildNodes->[0]->toString);
    }

    my $values  = {};

    if (defined $self->handler && $self->metadataPrefix eq $self->handler->metadataPrefix) {
        $values  = $self->handler->parse($dom) // {};
    }

    my $data = {
        _id => $identifier ,
        _identifier => $identifier ,
        _datestamp  => $datestamp ,
        _status     => $status ,
        _metadata   => $metadata ,
        _setSpec    => $sets ,
        _about      => $about ,
        %$values
    };

    $data;
}

sub _args {
    my ($self) = @_;
    
    my %args = (
        metadataPrefix => $self->metadataPrefix,
        set => $self->set ,
        from => $self->from ,
        until => $self->until ,
    );
    for( keys %args ) {
        delete $args{$_} if !defined($args{$_}) || !length($args{$_});
    } 

    return %args;
}

sub generator {
    my ($self) = @_;
    return $self->dry ?
    sub {
        state $called = 0;
        return if $called;
        $called = 1;
        # TODO: make sure that HTTP::OAI does not change this internal method
        return { 
            url => $self->oai->_buildurl( $self->_args, verb => 'ListIdentifiers' )
        };
    } : sub {
        state $res = $self->oai->ListRecords( $self->_args );
        if ($res->is_error) {
            warn $res->message;
            return;
        }
        if (my $rec = $res->next) {
            return $self->_map_record($rec);
        }
        return;
    };
}

=head1 NAME

Catmandu::Importer::OAI - Package that imports OAI-PMH feeds

=head1 SYNOPSIS

    use Catmandu::Importer::OAI;

    my $importer = Catmandu::Importer::OAI->new(
                    url => "...",
                    metadataPrefix => "..." ,
                    from => "..." ,
                    until => "..." ,
                    set => "...",
                    handler => "..." );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 CONFIGURATION

=over

=item url

=item metadataPrefix

=item handler

=item set

=item from

=item until

=item dry

Don't do any HTTP requests but return URLs that data would be queried from. 

=back

=head1 DESCRIPTION

Every Catmandu::Importer is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::OAI methods are not idempotent: OAI-PMH
feeds can only be read once.

To parse metadata records into Perl hashes optionally
a handler can be provided. This is a Perl package that implements two methods:

  * metadataPrefix  - which should return a metadataPrefix string for which it can parse
  the metadata
  * parse($dom) - which recieves a XML::LibXML::DOM object and should return a Perl hash

E.g.

  package MyHandler;

  use Moo;

  has metadataPrefix => (is => 'ro' , default => sub { "oai_dc" });

  sub parse {
      my ($self,$dom) = @_;
      return {};
  }

=cut

1;
