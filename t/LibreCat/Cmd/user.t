use strict;
use warnings FATAL => 'all';
use Path::Tiny;
use LibreCat load => (layer_paths => [qw(t/layer)]);

use Catmandu::Sane;
use Catmandu;

use LibreCat::CLI;
use Test::More;
use Test::Exception;
use App::Cmd::Tester::CaptureExternal;
use Cpanel::JSON::XS;

my $pkg;

BEGIN {
    $pkg = 'LibreCat::Cmd::user';
    use_ok $pkg;
}

require_ok $pkg;

# empty db
Catmandu->store('main')->bag('user')->delete_all;
Catmandu->store('search')->bag('user')->delete_all;

{
    my $result = test_app(qq|LibreCat::CLI| => ['user']);
    ok $result->error, 'missing cmd: threw an exception';
}

{
    my $result = test_app(qq|LibreCat::CLI| => ['user', 'list']);

    ok !$result->error, 'list: ok threw no exception';

    my $output = $result->stdout;
    ok $output , 'list: got an output';

    my $count = count_user($output);

    ok $count == 0, 'list: got no users';
}

{
    my $result = test_app(
        qq|LibreCat::CLI| => ['user', 'add', 't/records/invalid-user.yml']);
    ok $result->error, 'add invalid user: threw an exception';
}

{
    my $result = test_app(
        qq|LibreCat::CLI| => ['user', 'add', 't/records/valid-user.yml']);

    ok !$result->error, 'add valid user: threw no exception';

    my $output = $result->stdout;
    ok $output , 'add valid user: got an output';

    like $output , qr/^added 999111999/, 'add valid user: id is 99111999';
}

{
    my $result = test_app(qq|LibreCat::CLI| => ['user', 'get', '999111999']);

    ok !$result->error, 'get: threw no exception';

    my $output = $result->stdout;

    ok $output , 'get: got an output';

    my $importer = Catmandu->importer('YAML', file => \$output);

    my $record = $importer->first;

    is $record->{_id}, '999111999', 'got really a 999111999 record';
    is $record->{email}, 'test.user@physics.com', 'got correct email';
}

{
    my $result
        = test_app(qq|LibreCat::CLI| => ['user', 'delete', '999111999']);

    ok !$result->error, 'delete: threw no exception';

    my $output = $result->stdout;
    ok $output , 'delete: got an output';

    like $output , qr/^deleted 999111999/, 'deleted 999111999';
}

{
    my $result = test_app(qq|LibreCat::CLI| => ['user', 'get', '999111999']);

    ok $result->error, 'ok no exception';

    my $output = $result->stdout;
    ok length($output) == 0, 'got no result';
}

{
    my $result = test_app(qq|LibreCat::CLI| => ['user', 'update_stats']);

    ok !$result->error, 'ok no exception';
}

done_testing;

sub count_user {
    my $str = shift;
    my @lines = grep {!/(^count:|.*\sdeleted\s.*)/} split(/\n/, $str);
    int(@lines);
}
