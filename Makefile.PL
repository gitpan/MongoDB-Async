use strict;
use warnings;
use lib 'ext';
use inc::Module::Install;


name 'MongoDB-Async';
perl_version '5.8.8';
author 'Florian Ragwitz <rafl@debian.org>';
author 'Kristina Chodorow <kristina@10gen.com>';
author 'Sergey Gorelov <nyaknyan@gmail.com>';
license 'Apache';
all_from 'lib/MongoDB/Async.pm';

requires 'Any::Moose';
# C::M::Modifiers isn't always needed. It'll be used only if Any::Moose decides
# to use Mouse instead of Moose. We depend on it anyway to make sure it's there
# when it's needed.
requires 'Coro';
requires 'EV';
requires 'Class::Method::Modifiers';
requires 'Digest::MD5';
requires 'Tie::IxHash';
requires 'DateTime';
requires 'XSLoader';
requires 'boolean';
test_requires 'Test::Exception';
test_requires 'Tie::IxHash';
test_requires 'DateTime';
test_requires 'boolean';
test_requires 'Data::Types';
test_requires 'File::Slurp';
test_requires 'FileHandle';
test_requires 'JSON';
test_requires 'File::Temp' => '0.17';
test_requires 'Try::Tiny';

mongo;

no_index directory => 'ext';

repository 'git://github.com/mongodb/mongo-perl-driver.git';


if ($Config::Config{useithreads}) {
    tests 't/*.t t/threads/*.t';
}

WriteAll;

package MY;
our $VERSION = '0.45';

use Config;

sub const_cccmd {
    my $inherited = shift->SUPER::const_cccmd(@_);
    return '' unless $inherited;

    if ($Config{cc} =~ /^cl\b/) {
        warn 'you are using MSVC... my condolences.';
        $inherited .= ' /Fo$@';
    }
    else {
        $inherited .= ' -o $@';
    }

    if ($Config{use64bitint}) {
        $inherited .= ' -DUSE_64_BIT_INT';
    }
    else {
        $inherited .= ' ';
    }

	# Search for Coro and EV
		my %opt;
		for my $opt (split /:+/, $ENV{PERL_MM_OPT}) {
		   my ($k,$v) = split /=/, $opt;
		   $opt{$k} = $v;
		}
		
		my $extra = $Config{sitearch};
		$extra =~ s/$Config{prefix}/$opt{PREFIX}/ if exists $opt{PREFIX};

		for my $d ($extra, @INC) {
		   if (-e "$d/Coro/CoroAPI.h") {
			  $inherited .=" -I$d/Coro";;
			  last;
		   }
		}
		
		for my $d ($extra, @INC) {
		   if (-e "$d/EV/EVAPI.h") {
			  $inherited .= " -I$d/EV -I$d";
			  last;
		   }
		}
	
	
	
    return $inherited;
}