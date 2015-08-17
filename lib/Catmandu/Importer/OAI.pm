package Catmandu::Importer::OAI;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use Scalar::Util qw(blessed);
use HTTP::OAI;
use Data::Dumper;
use Carp;

with 'Catmandu::Importer';

has url     => (is => 'ro', required => 1);
has metadataPrefix => (is => 'ro' , default => sub { "oai_dc" });
has handler => (is => 'rw', lazy => 1 , builder => 1, coerce => \&_coerce_handler );
has xslt    => (is => 'ro', coerce => \&_coerce_xslt );
has set     => (is => 'ro');
has from    => (is => 'ro');
has until   => (is => 'ro');
has resumptionToken => (is => 'ro');
has oai     => (is => 'ro', lazy => 1, builder => 1);
has dry     => (is => 'ro');
has listIdentifiers => (is => 'ro');

sub _build_handler {
    my ($self) = @_;
    if ($self->metadataPrefix eq 'oai_dc') {
        return 'oai_dc';
    } 
    elsif ($self->metadataPrefix eq 'marcxml') {
        return 'marcxml';
    }
    else {
        return 'struct';
    }
}

sub _coerce_handler {
  my ($handler) = @_;

  return $handler if is_invocant($handler) or is_code_ref($handler);

  if (is_string($handler) && !is_number($handler)) {
      my $class = $handler =~ /^\+(.+)/ ? $1
        : "Catmandu::Importer::OAI::Parser::$handler";

      my $handler;
      eval {
          $handler = Catmandu::Util::require_package($class)->new;
      };
      if ($@) {
        croak $@;
      } else {
        return $handler;
      }
  }

  return sub { return { _metadata => readXML($_[0]) } };
}

sub _coerce_xslt {
  eval {
    Catmandu::Util::require_package('Catmandu::XML::Transformer')
      ->new( stylesheet => $_[0] )
  } or croak $@;
}

sub _build_oai {
    my ($self) = @_;
    HTTP::OAI::Harvester->new(baseURL => $self->url, resume => 0);
}

sub _map_record {
    my ($self, $rec) = @_;

    my $sets       = [ $rec->header->setSpec ];
    my $identifier = $rec->identifier;
    my $datestamp  = $rec->datestamp;
    my $status     = $rec->status // "";
    my $dom        = $rec->metadata ? $rec->metadata->dom->nonBlankChildNodes->[0]->nonBlankChildNodes->[0] : undef;
    my $about      = [];

    for ($rec->about) {
        push(@$about , $_->dom->nonBlankChildNodes->[0]->nonBlankChildNodes->[0]->toString);
    }

    my $values = $self->handle_record($dom) // { };

    my $data = {
        _id => $identifier ,
        _identifier => $identifier ,
        _datestamp  => $datestamp ,
        _status     => $status ,
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

sub handle_record {
    my ($self, $dom) = @_;
    return unless $dom;

    $dom = $self->xslt->transform($dom) if $self->xslt;
    return blessed($self->handler)
         ? $self->handler->parse($dom)
         : $self->handler->($dom);
}

sub dry_run {
    my ($self) = @_;
    sub {
        state $called = 0;
        return if $called;
        $called = 1;
        # TODO: make sure that HTTP::OAI does not change this internal method
        return { 
            url => $self->oai->_buildurl( 
                $self->_args, 
                verb => ($self->listIdentifiers ? 'ListIdentifiers' : 'ListRecords')
            )
        };
    };
}

sub oai_run {
    my ($self) = @_;
    sub {
        state $stack = [];
        state $resumptionToken = $self->resumptionToken;
        state $done  = 0;

        my $fill_stack = sub {
            push @$stack , shift;
        };

        if (@$stack <= 1 && $done == 0) {
            my %args = $self->_args;

            # Use the resumptionToken if one found on the last run, or if it was
            # undefined (last record)
            if (defined $resumptionToken) {
                my $verb = $args{verb};
                %args = (verb => $verb , resumptionToken => $resumptionToken);
            }

            my $res = $self->listIdentifiers 
                ? $self->oai->ListIdentifiers( %args , onRecord => $fill_stack )
                : $self->oai->ListRecords( %args , onRecord => $fill_stack );

            if ($res->is_error) {
                my $token = $resumptionToken // '';
                $self->log->error("resumptionToken($token) : " . $res->message);
                carp "resumptionToken($token) : " . $res->message;
                return undef;
            }

            if (defined $res->resumptionToken) {
                $resumptionToken = $res->resumptionToken->resumptionToken;
            }
            else {
                $resumptionToken = undef;
            }
           
            unless (defined $resumptionToken && length $resumptionToken) {
                $done = 1;
            }
        }

        if (my $rec = shift @$stack) {
            if ($rec->isa('HTTP::OAI::Record')) {
                return $self->_map_record($rec);
            } else {
                return {
                    _id => $rec->identifier,
                    _datestamp  => $rec->datestamp,
                    _status => $rec->status // "",
                }
            }
        }

        return undef;
    };
}

sub generator {
    my ($self) = @_;
    return $self->dry ? $self->dry_run : $self->oai_run;
}

1;
__END__

=head1 NAME

Catmandu::Importer::OAI - Package that imports OAI-PMH feeds

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert OAI --url http://myrepo.org/oai

    $ catmandu convert OAI --url http://myrepo.org/oai --metadataPrefix didl --handler RAW

    # In perl
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

OAI-PMH Base URL.

=item metadataPrefix

Metadata prefix to specify the metadata format. Set to C<oai_dc> by default. 

=item handler( sub {} | $object | 'NAME' | '+NAME' )

Handler to transform each record from XML DOM (L<XML::LibXML::Element>) into
Perl hash.

Handlers can be provided as function reference, an instance of a Perl 
package that implements 'parse', or by a package NAME. Package names should
be prepended by C<+> or prefixed with C<Catmandu::Importer::OAI::Parser>. E.g
C<foobar> will create a C<Catmandu::Importer::OAI::Parser::foobar> instance.

By default the handler L<Catmandu::Importer::OAI::Parser::oai_dc> is used for
metadataPrefix C<oai_dc>,  L<Catmandu::Importer::OAI::Parser::marcxml> for
C<marcxml>, and L<Catmandu::Importer::OAI::Parser::struct> for other formats.
In addition there is L<Catmandu::Importer::OAI::Parser::raw> to return the XML
as it is.

=item set

An optional set for selective harvesting.

=item from

An optional datetime value (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ) as lower bound
for datestamp-based selective harvesting.

=item until

An optional datetime value (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ) as upper bound
for datestamp-based selective harvesting.

=item listIdentifiers

Harvest identifiers instead of full records.

=item resumptionToken

An optional resumptionToken to start harvesting from.

=item dry

Don't do any HTTP requests but return URLs that data would be queried from. 

=item xslt

Preprocess XML records with XSLT script(s) given as comma separated list or
array reference. Requires L<Catmandu::XML>.

=back

=head1 DESCRIPTION

Every Catmandu::Importer is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::OAI methods are not idempotent: OAI-PMH
feeds can only be read once.

=head1 METHOD

In addition to methods inherited from L<Catmandu::Iterable>, this module
provides the following public methods:

=head2 handle_record( $dom )

Process an XML DOM as with xslt and handler as configured and return the
result.

=cut
