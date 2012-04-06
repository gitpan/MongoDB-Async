#
#  Copyright 2009 10gen, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

package MongoDB::Async::Pool;
our $VERSION = '0.1';

use MongoDB::Async;
# use Scalar::Util qw/weaken/;
use strict;


=head1 NAME

MongoDB::Async::Pool - Connection pool

=head1 SYNOPSIS

The MongoDB::Async::Pool class creates a poll of L<MongoDB::Async::Connection> connections

=head1 METHODS

=head2 new({ MongoDB::Async::Connection args }, { MongoDB::Async::Pool args });

Creates pool of L<MongoDB::Async::Connection> objects

=cut

#ATTRIBUTES:

#=head3 max_conns

#Max connection count. ->get will block current coroutine when max_conns reached
#Default: 0 - no limit



#=head3 timeout
#Timeout (sec) to close unused connections.
#0 - don`t close
#Default: 10


sub new {
	my $pkgname = $_[0];
	my $self = $_[2] || {};
	
	$self->{conn_args} = $_[1] || {};
	
	$self->{timeout} = 10 unless exists $self->{timeout};
	$self->{limit} = 0 unless exists $self->{limit};
	
	$self->{pool} = [];
	
	bless $self, $pkgname;
}

=head2 $pool->get;

Returns L<MongoDB::Async::Connection> object. You don`t need to think about returning object to pool, it`ll be returned on DESTROY

=cut

sub pop {
	my $self = shift;
	my $conn;
	
	
	return $conn if ( $conn = pop @{$self->{pool}} );
	
	$conn = MongoDB::Async::Connection->new($self->{conn_args});
	
	$conn->{_parent_pool} = $self->{pool};
	
	$self->{init}->($conn) if($self->{init});
	
	return $conn;
}

*get = \&pop;
*AUTOLOAD = \&pop;


=head1 TODO

Opened connections limit

Timeout to close unused connections

=cut
