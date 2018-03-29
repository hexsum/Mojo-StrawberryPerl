package Config::Any::Base;

use strict;
use warnings;

=head1 NAME

Config::Any::Base - Base class for loaders

=head1 DESCRIPTION

This is a base class for all loaders. It currently handles the specification
of dependencies in order to ensure the subclass can load the config file
format.

=head1 METHODS

=head2 is_supported( )

Allows us to determine if the file format can be loaded. The can be done via
one of two subclass methods:

=over 4

=item * C<requires_all_of()> - returns an array of items that must all be present in order to work

=item * C<requires_any_of()> - returns an array of items in which at least one must be present

=back

You can specify a module version by passing an array reference in the return.

    sub requires_all_of { [ 'My::Module', '1.1' ], 'My::OtherModule' }

Lack of specifying these subs will assume you require no extra modules to function.

=cut

sub is_supported {
    my ( $class ) = shift;
    if ( $class->can( 'requires_all_of' ) ) {
        eval join( '', map { _require_line( $_ ) } $class->requires_all_of );
        return $@ ? 0 : 1;
    }
    if ( $class->can( 'requires_any_of' ) ) {
        for ( $class->requires_any_of ) {
            eval _require_line( $_ );
            return 1 unless $@;
        }
        return 0;
    }

    # requires nothing!
    return 1;
}

sub _require_line {
    my ( $input ) = shift;
    my ( $module, $version ) = ( ref $input ? @$input : $input );
    return "require $module;"
        . ( $version ? "${module}->VERSION('${version}');" : '' );
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<Config::Any>

=back

=cut

1;
