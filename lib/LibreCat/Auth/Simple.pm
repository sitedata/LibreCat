package LibreCat::Auth::Simple;

use Catmandu::Sane;
use Moo;
use namespace::clean;

with 'LibreCat::Auth';

has users => (is => 'ro', required => 1);

sub _authenticate {
    my ($self, $params) = @_;
    $username = $params->{username} // return 0;
    $password = $params->{password} // return 0;
    $user = $self->users->{$username} // return 0;
    if (exists $user->{password} && $password ne $user->{password}) {
        return 0;
    }
    1;
}

1;

__END__

=pod

=head1 NAME

LibreCat::Auth::Simple - A simple in-memory LibreCat
authentication package

=head1 SYNOPSIS

    use LibreCat::Auth::Simple;

    my $auth = Auth::Simple->new(
        users => {
            nicolas => {password => '1234'},
            # user test can use any password
            test => {},
        }
    );

    if ($auth->authenticate({username => $username,
            password => $password})) {
        say "logged in";
    }
    else {
        say "error";
    }

=head1 CONFIG

=head2 users

A hash ref with user credentials. If no password is specified, any
password grant access.

    {
        nicolas => {password => '1234'},
        # user test can use any password
        test => {},
    }

=head1 SEE ALSO

L<LibreCat::Auth>

=cut
