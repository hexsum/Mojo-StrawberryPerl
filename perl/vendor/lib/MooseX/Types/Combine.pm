use strict;
use warnings;
package MooseX::Types::Combine;
# ABSTRACT: Combine type libraries for exporting

our $VERSION = '0.46';

use Module::Runtime 'use_module';
use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod     package CombinedTypeLib;
#pod
#pod     use base 'MooseX::Types::Combine';
#pod
#pod     __PACKAGE__->provide_types_from(qw/TypeLib1 TypeLib2/);
#pod
#pod     package UserClass;
#pod
#pod     use CombinedTypeLib qw/Type1 Type2 ... /;
#pod
#pod =head1 DESCRIPTION
#pod
#pod Allows you to export types from multiple type libraries.
#pod
#pod Libraries on the right end of the list passed to L</provide_types_from>
#pod take precedence over those on the left in case of conflicts.
#pod
#pod =cut

sub import {
    my ($class, @types) = @_;
    my $caller = caller;

    my %types = $class->_provided_types;

    if ( grep { $_ eq ':all' } @types ) {
        $_->import( { -into => $caller }, q{:all} )
            for $class->provide_types_from;
        return;
    }

    my %from;
    for my $type (@types) {
        unless ($types{$type}) {
            my @type_libs = $class->provide_types_from;

            die
                "$caller asked for a type ($type) which is not found in any of the"
                . " type libraries (@type_libs) combined by $class\n";
        }

        push @{ $from{ $types{$type} } }, $type;
    }

    $_->import({ -into => $caller }, @{ $from{ $_ } })
        for keys %from;
}

#pod =head1 CLASS METHODS
#pod
#pod =head2 provide_types_from
#pod
#pod Sets or returns a list of type libraries to re-export from.
#pod
#pod =cut

sub provide_types_from {
    my ($class, @libs) = @_;

    my $store =
     do { no strict 'refs'; \@{ "${class}::__MOOSEX_TYPELIBRARY_LIBRARIES" } };

    if (@libs) {
        $class->_check_type_lib($_) for @libs;
        @$store = @libs;

        my %types = map {
            my $lib = $_;
            map +( $_ => $lib ), $lib->type_names
        } @libs;

        $class->_provided_types(%types);
    }

    @$store;
}

sub _check_type_lib {
    my ($class, $lib) = @_;

    use_module($lib);

    die "Cannot use $lib in a combined type library, it does not provide any types"
        unless $lib->can('type_names');
}

sub _provided_types {
    my ($class, %types) = @_;

    my $types =
     do { no strict 'refs'; \%{ "${class}::__MOOSEX_TYPELIBRARY_TYPES" } };

    %$types = %types
        if keys %types;

    %$types;
}

#pod =head1 SEE ALSO
#pod
#pod L<MooseX::Types>
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Combine - Combine type libraries for exporting

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    package CombinedTypeLib;

    use base 'MooseX::Types::Combine';

    __PACKAGE__->provide_types_from(qw/TypeLib1 TypeLib2/);

    package UserClass;

    use CombinedTypeLib qw/Type1 Type2 ... /;

=head1 DESCRIPTION

Allows you to export types from multiple type libraries.

Libraries on the right end of the list passed to L</provide_types_from>
take precedence over those on the left in case of conflicts.

=head1 CLASS METHODS

=head2 provide_types_from

Sets or returns a list of type libraries to re-export from.

=head1 SEE ALSO

L<MooseX::Types>

=head1 AUTHOR

Robert "phaylon" Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Robert "phaylon" Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
