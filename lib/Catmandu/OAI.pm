package Catmandu::OAI;

=head1 NAME

Catmandu::OAI - Catmandu modules for working with OAI repositories

=head1 SYNOPSIS

  # From the command line
  $ catmandu convert OAI --url http://biblio.ugent.be/oai --set allFtxt
  $ catmandu import OAI --url http://biblio.ugent.be/oai --set allFtxt to MongoDB --database-name biblio

  # From Perl
  use Catmandu;

  my $importer = Catmandu->importer('OAI',url => 'http://biblio.ugent.be/oai' , set => 'allFtxt');

  $importer->each(sub {
	my $item = shift;

	print "%s %s\n", $item->{_identifier} , $item->{title}->[0];
  });

=cut


our $VERSION = '0.02';

=head1 MODULES

=over

=item * L<Catmandu::Importer::OAI>

=back

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

Jakob Voss, C<< <nichtich at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ghent University Library

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

