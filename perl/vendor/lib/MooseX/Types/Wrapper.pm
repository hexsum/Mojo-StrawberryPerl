package MooseX::Types::Wrapper;
# ABSTRACT: Wrap exports from a library

our $VERSION = '0.46';

use Moose;
use Carp::Clan      qw( ^MooseX::Types );
use Module::Runtime 'use_module';

use namespace::autoclean;

extends 'MooseX::Types';

#pod =head1 DESCRIPTION
#pod
#pod See L<MooseX::Types/SYNOPSIS> for detailed usage.
#pod
#pod =head1 METHODS
#pod
#pod =head2 import
#pod
#pod =cut

sub import {
    my ($class, @args) = @_;
    my %libraries = @args == 1 ? (Moose => $args[0]) : @args;

    for my $l (keys %libraries) {

        croak qq($class expects an array reference as import spec)
            unless ref $libraries{ $l } eq 'ARRAY';

        my $library_class
          = ($l eq 'Moose' ? 'MooseX::Types::Moose' : $l );
        use_module($library_class);

        $library_class->import({
            -into    => scalar(caller),
            -wrapper => $class,
        }, @{ $libraries{ $l } });
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Wrapper - Wrap exports from a library

=head1 VERSION

version 0.46

=head1 DESCRIPTION

See L<MooseX::Types/SYNOPSIS> for detailed usage.

=head1 METHODS

=head2 import

=head1 SEE ALSO

L<MooseX::Types>

=head1 AUTHOR

Robert "phaylon" Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Robert "phaylon" Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
