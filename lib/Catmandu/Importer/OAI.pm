package Catmandu::Importer::OAI::DC;
use Moo;

has dom => (is => 'ro');

sub parse {
    my ($self) = @_;
    
    return undef unless $self->dom;
    
    my $rec = {};
    
    for ($self->dom->findnodes("./*")) {
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
has handler => (is => 'ro' , default => sub { "Catmandu::Importer::OAI::DC"} );
has set     => (is => 'ro');
has from    => (is => 'ro');
has until   => (is => 'ro');
has oai     => (is => 'ro', lazy => 1, builder => '_build_oai');

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
    
    my $handler = Catmandu::Importer::OAI::DC->new(dom => $dom);
    my $values  = $handler->parse // {};

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

sub generator {
    my ($self) = @_;
    sub {
        state $res = $self->oai->ListRecords(
                                metadataPrefix => $self->metadataPrefix, 
                                set => $self->set , 
                                from => $self->from , 
                                until => $self->until ,
                    );
        
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
                    set => "..." );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new(url => URL,[set => [qw(...)])

Create a new OAI-PMH importer for the URL. Optionally provide a set parameter with the
OAI-PMH set you want to import.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::OAI methods are not idempotent: OAI-PMH feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
