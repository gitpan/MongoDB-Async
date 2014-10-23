use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;

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
    plan tests => 8;
}

my $db = $conn->get_database('test_database');
$db->drop;

my $now = DateTime->now;
{
    $db->get_collection( 'test_collection' )->insert( { date => $now } );

    my $date1 = $db->get_collection( 'test_collection' )->find_one->{date};
    isa_ok $date1, 'DateTime';
    is $date1->epoch, $now->epoch;
    $db->drop;
}

{
    $db->get_collection( 'test_collection' )->insert( { date => $now } );
    $MongoDB::Async::BSON::dt_type =  undef ;
    my $date3 = $db->get_collection( 'test_collection' )->find_one->{date};
    ok( not ref $date3 );
    is $date3, $now->epoch;
    $db->drop;
}


{
    $db->get_collection( 'test_collection' )->insert( { date => $now } );
    $MongoDB::Async::BSON::dt_type = 'DateTime::Tiny' ;
    my $date2 = $db->get_collection( 'test_collection' )->find_one->{date};
    isa_ok( $date2, 'DateTime::Tiny' );
    is $date2->DateTime->epoch, $now->epoch;
    $db->drop;
}


# roundtrips

{
    $MongoDB::Async::BSON::dt_type =  'DateTime' ;
    my $coll = $db->get_collection( 'test_collection' );
    $coll->insert( { date => $now } );
    my $doc = $coll->find_one;

    $doc->{date}->add( seconds => 60 );

    $coll->update( { _id => $doc->{_id} }, { date => $doc->{date} } );

    my $doc2 = $coll->find_one;
    is( $doc2->{date}->epoch, ( $now->epoch + 60 ) );
}


{
    $MongoDB::Async::BSON::dt_type = 'DateTime::Tiny' ;
    my $dtt_now = DateTime::Tiny->now;
    my $coll = $db->get_collection( 'test_collection' );
    $coll->insert( { date => $dtt_now } );
    my $doc = $coll->find_one;

    $doc->{date} = DateTime::Tiny->from_string( $doc->{date}->DateTime->add( seconds => 60 )->iso8601 );
    $coll->update( { _id => $doc->{_id} }, $doc );

    my $doc2 = $coll->find_one( { _id => $doc->{_id} } );

    is( $doc2->{date}->DateTime->epoch, ( $now->epoch + 60 ) );
}

