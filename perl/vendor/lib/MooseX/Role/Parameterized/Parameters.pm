package MooseX::Role::Parameterized::Parameters;
# ABSTRACT: base class for parameters
$MooseX::Role::Parameterized::Parameters::VERSION = '1.08';
use Moose;
__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Role::Parameterized::Parameters - base class for parameters

=head1 VERSION

version 1.08

=head1 DESCRIPTION

This is the base class for parameter objects. Currently empty, but I reserve
the right to add things here.

Each parameterizable role gets their own anonymous subclass of this;
L<MooseX::Role::Parameterized/parameter> actually operates on these anonymous
subclasses.

Each parameterized role gets their own instance of the anonymous subclass
(owned by the parameterizable role).

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
