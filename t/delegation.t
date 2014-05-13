use strict;
use warnings;
use Test::More;

use MongoDB::Async::Timestamp; # needed if db is being run as master
use MongoDB::Async;
use DateTime;
use DateTime::Tiny;

my $conn;
eval {
    my $host = "localhost";
    if (exists $ENV{MONGOD}) {
        $host = $ENV{MONGOD};
    }
    $conn = MongoDB::Async::MongoClient->new(host => $host, ssl => $ENV{MONGO_SSL});
};

if ($@) {
    plan skip_all => $@;
}
else {
    plan tests => 1;
}


# test that Connection delegates constructor params to MongoClient correctly
my $conn2 = MongoDB::Async::Connection->new( host => '127.0.0.1' );

is ( $conn2->host, '127.0.0.1' );
