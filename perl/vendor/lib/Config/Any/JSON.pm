package Config::Any::JSON;

use strict;
use warnings;

use base 'Config::Any::Base';

=head1 NAME

Config::Any::JSON - Load JSON config files

=head1 DESCRIPTION

Loads JSON files. Example:

    {
        "name": "TestApp",
        "Controller::Foo": {
            "foo": "bar"
        },
        "Model::Baz": {
            "qux": "xyzzy"
        }
    }

=head1 METHODS

=head2 extensions( )

return an array of valid extensions (C<json>, C<jsn>).

=cut

sub extensions {
    return qw( json jsn );
}

=head2 load( $file )

Attempts to load C<$file> as a JSON file.

=cut

sub load {
    my $class = shift;
    my $file  = shift;

    open( my $fh, $file ) or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;

    eval { require JSON::DWIW; };
    unless( $@ ) {
        my $decoder = JSON::DWIW->new;
        my ( $data, $error ) = $decoder->from_json( $content );
        die $error if $error;
        return $data;
    }

    eval { require JSON::XS; };
    unless( $@ ) {
        my $decoder = JSON::XS->new->relaxed;
        return $decoder->decode( $content );
    }

    eval { require JSON::Syck; };
    unless( $@ ) {
        return JSON::Syck::Load( $content );
    }

    eval { require JSON::PP; JSON::PP->VERSION( 2 ); };
    unless( $@ ) {
        my $decoder = JSON::PP->new->relaxed;
        return $decoder->decode( $content );
    }

    require JSON;
    eval { JSON->VERSION( 2 ); };
    return $@ ? JSON::jsonToObj( $content ) : JSON::from_json( $content );
}

=head2 requires_any_of( )

Specifies that this modules requires one of,  L<JSON::DWIW>, L<JSON::XS>,
L<JSON::Syck> or L<JSON> in order to work.

=cut

sub requires_any_of { 'JSON::DWIW', 'JSON::XS', 'JSON::Syck', 'JSON::PP', 'JSON' }

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2016 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<Catalyst>

=item * L<Config::Any>

=item * L<JSON::DWIW>

=item * L<JSON::XS>

=item * L<JSON::Syck>

=item * L<JSON>

=back

=cut

1;
