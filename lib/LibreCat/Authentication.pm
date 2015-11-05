package LibreCat::Authentication;

use namespace::clean;
use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Logger';

requires '_authenticate';

has obfuscate_params => (is => 'lazy');

sub _build_obfuscate_params {
    [qw(password)];
}

sub authenticate {
    my ($self, $params) = @_;
    if ($self->log->is_debug) {
        my $p = [%$params];
        for my $k (@{$self->obfuscate_params}) {
            $p->{$k} = '*' x 8 if exists $p->{$k};
        }
        $self->log->debugf("authenticating: %s", $p);
    }
    $self->_authenticate($params);
}

1;

__END__

=pod

=head1 NAME

LibreCat::Authentication - LibreCat authentication role

=head1 SYNOPSIS

    package MyAuthentication;

    use Moo;

    with 'LibreCat::Authentication';

    sub authenticate {
        my ($self,$params) = @_;
        $params->{password} eq 'secret';
    }

    1;

=head1 DESCRIPTION

This is a Moo::Role for all authentication packages. It requires
C<authenticate> method.

=head1 CONFIG

=over 4

=item obfuscate_params

An array ref of params to obfuscate in logging or error reporting with
'********'. The default obfuscates 'password'.

=back

=head1 METHODS

=head2 authenticate(\%params)

All authentication packages need to implement this method.
Returns 1 on success, 0 on failure.

=head1 SEE ALSO

L<LibreCat::Authentication::Simple>,
L<LibreCat::Authentication::Multi>,
L<LibreCat::Authentication::LDAP>

=cut
