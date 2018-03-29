package Config::Any::Perl;

use strict;
use warnings;

use base 'Config::Any::Base';

=head1 NAME

Config::Any::Perl - Load Perl config files

=head1 DESCRIPTION

Loads Perl files. Example:

    {
        name => 'TestApp',
        'Controller::Foo' => {
            foo => 'bar'
        },
        'Model::Baz' => {
            qux => 'xyzzy'
        }
    }

=head1 METHODS

=head2 extensions( )

return an array of valid extensions (C<pl>, C<perl>).

=cut

sub extensions {
    return qw( pl perl );
}

=head2 load( $file )

Attempts to load C<$file> as a Perl file.

=cut

sub load {
    my $class = shift;
    my $file  = shift;

    my( $exception, $content );
    {
        local $@;
        $content = do $file;
        $exception = $@;
    }
    die $exception if $exception;

    return $content;
}

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

=back

=cut

1;
