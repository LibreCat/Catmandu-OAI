# NAME

Catmandu::OAI - Catmandu modules for working with OAI repositories

# SYNOPSIS

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

# MODULES

- [Catmandu::Importer::OAI](https://metacpan.org/pod/Catmandu::Importer::OAI)

# AUTHOR

Nicolas Steenlant, `<nicolas.steenlant at ugent.be>`

# CONTRIBUTOR

Patrick Hochstenbach, `<patrick.hochstenbach at ugent.be>`

Jakob Voss, `<nichtich at cpan.org>`

# LICENSE AND COPYRIGHT

Copyright 2012 Ghent University Library

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
