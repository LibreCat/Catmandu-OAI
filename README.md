# NAME

Catmandu::OAI - Catmandu modules for working with OAI repositories

# SYNOPSIS

    # From the command line
    $ catmandu convert OAI --url http://biblio.ugent.be/oai --set allFtxt
    $ catmandu convert OAI --url http://biblio.ugent.be/oai --metadataPrefix mods --set books
    $ catmandu convert OAI --url http://biblio.ugent.be/oai --metadataPrefix mods --set books --handler raw
    $ catmandu import OAI --url http://biblio.ugent.be/oai --set allFtxt to MongoDB --database-name biblio

    # Harvest repository description
    $ catmandu convert OAI --url http://myrepo.org/oai --identify 1

    # Harvest identifiers
    $ catmandu convert OAI --url http://myrepo.org/oai --listIdentifiers 1

    # Harvest sets
    $ catmandu convert OAI --url http://myrepo.org/oai --listSets 1

    # Harvest metadataFormats
    $ catmandu convert OAI --url http://myrepo.org/oai --listMetadataFormats 1

    # Harvest one record
    $ catmandu convert OAI --url http://myrepo.org/oai --getRecord 1 --identifier oai:myrepo:1234

# MODULES

- [Catmandu::Importer::OAI](https://metacpan.org/pod/Catmandu::Importer::OAI)

# AUTHOR

Nicolas Steenlant, `<nicolas.steenlant at ugent.be>`

# CONTRIBUTOR

Patrick Hochstenbach, `<patrick.hochstenbach at ugent.be>`

Jakob Voss, `<nichtich at cpan.org>`

Nicolas Franck, `<nicolas.franck at ugent.be>`

# LICENSE AND COPYRIGHT

Copyright 2016 Ghent University Library

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
