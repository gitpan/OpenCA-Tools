## OpenCA::Tools
##
## Copyright (C) 1998-1999 Massimiliano Pala (madwolf@openca.org)
## All rights reserved.
##
## This library is free for commercial and non-commercial use as long as
## the following conditions are aheared to.  The following conditions
## apply to all code found in this distribution, be it the RC4, RSA,
## lhash, DES, etc., code; not just the SSL code.  The documentation
## included with this distribution is covered by the same copyright terms
## 
## Copyright remains Massimiliano Pala's, and as such any Copyright notices
## in the code are not to be removed.
## If this package is used in a product, Massimiliano Pala should be given
## attribution as the author of the parts of the library used.
## This can be in the form of a textual message at program startup or
## in documentation (online or textual) provided with the package.
## 
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
## 1. Redistributions of source code must retain the copyright
##    notice, this list of conditions and the following disclaimer.
## 2. Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in the
##    documentation and/or other materials provided with the distribution.
## 3. All advertising materials mentioning features or use of this software
##    must display the following acknowledgement:
##    "This product includes OpenCA software written by Massimiliano Pala
##     (madwolf@openca.org) and the OpenCA Group (www.openca.org)"
## 4. If you include any Windows specific code (or a derivative thereof) from 
##    some directory (application code) you must include an acknowledgement:
##    "This product includes OpenCA software (www.openca.org)"
## 
## THIS SOFTWARE IS PROVIDED BY OPENCA DEVELOPERS ``AS IS'' AND
## ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
## ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
## FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
## DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
## OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
## HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
## LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
## OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
## SUCH DAMAGE.
## 
## The licence and distribution terms for any publically available version or
## derivative of this code cannot be changed.  i.e. this code cannot simply be
## copied and put under another distribution licence
## [including the GNU Public Licence.]
##

use strict;

package OpenCA::Tools;

$OpenCA::Tools::VERSION = '0.4.2a';

sub new {
	my $that = shift;
	my $class = ref($that) || $that;

	my $self = {};
	bless $self, $class;

	return $self;
}

sub getDate {

        ## Date function, so as to keep implementations
        ## more PERL dependant and external commands indipendant
        ## If we want GTM time, simply pass GMT as first argument
        ## to this function.

	my $self = shift;

        my $keys = { @_ };
	my $format = $keys->{FORMAT};
	my $date;

	$format = "GMT" if ( not $format );

        if( $format =~ /GMT/i ) {
                $date = gmtime() . " GMT";
        } else {
                $date = localtime();
        }

	return $date;
}

sub subVar {
	my $self = shift;

        my $keys = { @_ };
        my $ret;

        my $pageVar = $keys->{PAGE};
        my $varName = $keys->{NAME};
        my $var     = $keys->{VALUE};

	return "$pageVar" if( (not $varName) or (not $var));

        my $match = "\\$varName";
        $pageVar =~ s/$match/$var/g;

        return "$pageVar";
}

sub getFile {
        my $self = shift;
        my @keys = @_;

        my ( $ret, $temp );

        open( FD, $keys[0] ) || return;
        while ( $temp = <FD> ) {
                $ret .= $temp;
        };
        return $ret;
}

sub copyFiles {
	my $self = shift;
	my $keys = { @_ };

	my $src = $keys->{SRC};
	my $dst = $keys->{DEST};
	my $md  = $keys->{MODE};

	my @fileList = glob("$src");
	my ( @tmp, $tmpDst, $line, $file, $fileName );

	foreach $file (@fileList) {
		next if( (not -e $file) or ( -d $src) );
		if( -d "$dst" ) {
			$dst =~ s/\/$//g;
			( $fileName ) =
				( $file =~ /.*?[\/]*([^\/]+)$/g );
			$tmpDst = "$dst/$fileName";
		} else {
			$tmpDst = "$dst";
		}
			
		open( FD, "<$file" ) or return;
		open( DF, ">$tmpDst" ) or return;
			while( $line = <FD> ) {
				print DF $line;
			}
		close(DF);
		close(FD);

		if( $md =~ /MOVE/i ) {
			unlink("$file");
		};
	}

	return 1;
}

sub moveFiles {
	my $self = shift;

	return $self->copyFiles ( @_ , MODE=>"MOVE" );
}

sub deleteFiles {
	my $self = shift;
	my $keys = { @_ };

	my $dir    = $keys->{DIR};
	my $filter = $keys->{FILTER};

	my ( @tmp, $file );

	$filter = '*' if ( not $filter );
	$dir =~ s/\/$//g;

	my @fileList = glob("$dir/$filter");

	foreach $file (@fileList) {
		next if( not -e "$file" );
		unlink( $file );
	}

	return 1;
}

sub cmpDate {

	## This function should return a value > 0 if the
	## DATE_1 is greater than DATE_2, a value < 0 if the
	## DATE_1 is less than DATE_2.

	my $self = shift;
	my $keys = { @_ };
	my @monList = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul",
			  "Aug", "Sep", "Oct", "Nov", "Dec" );
	my ( $m1, $m2, $tmp );

	my $date1 = $keys->{DATE_1};
	my $date2 = $keys->{DATE_2};

	$date1 =~ s/([\D]*)$//g;
	$date2 =~ s/([\D]*)$//g;

	return if( (not $date1) or (not $date2) );

	my $mon = 0;

	my ( @T1 ) =
	 ( $date1 =~ /([\d]+)[\s]+([\d]+):([\d]+):([\d]+)[\s]+([\d]+)/g );
	my ( @T2 ) = 
	 ( $date2 =~ /([\d]+)[\s]+([\d]+):([\d]+):([\d]+)[\s]+([\d]+)/g );

	foreach $tmp (@monList) {
		$m1 = sprintf("%2.2d",$mon) if( $date1 =~ /$tmp/i );
		$m2 = sprintf("%2.2d",$mon) if( $date2 =~ /$tmp/i );
		$mon++;
	}
	
	my $dt1 = sprintf("%4.4d%s%2.2d%2.2d%2.2d%2.2d", $T1[4], $m1, $T1[0],
					 $T1[1], $T1[2], $T1[3]);
	my $dt2 = sprintf("%4.4d%s%2.2d%2.2d%2.2d%2.2d", $T2[4], $m2, $T2[0],
					 $T2[1], $T2[2], $T2[3]);

	my $ret = $dt1 - $dt2;

	return $ret;
}

sub isInsidePeriod {
	my $self = shift;
	my $keys = { @_ };

	my $date  = $keys->{DATE};
	my $start = $keys->{START};
	my $end   = $keys->{END};

	my $res;

	if( $start ) {
		$res = $self->cmpDate( DATE_1=>"$date", DATE_2=>"$start");
		return if( $res < 0 );
	};

	if ($end) {
		$res = $self->cmpDate( DATE_1=>"$date", DATE_2=>"$end"); 
		return if ($res > 0);
	};

	return 1;
}

sub parseDN {

	## This function is to provide a common parser to the
	## various tools.

	my $self = shift;
	my $keys = { @_ };
	
	my $dn = ( $keys->{DN} or $_[0] );
	my $item;
	my @ouList = ();
	my $ret = {};

	return if( not $dn );

	my ( @list ) = split( /\/|\,/, $dn );
	foreach $item (@list) {
		my ( $key, $value ) =
			( $item =~ /[\s]*(.*?)[\s]*\=[\s]*(.*)[\s]*/i );

		next if( not $key );
		$key = uc( $key );

		if( $key eq "OU" ) {
			push @ouList, $value;
		} else {
			$ret->{$key} = $value;
		}
	}

	$ret->{OU} = [ @ouList ];

	return $ret;
}


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

OpenCA::Tools - Misc Utilities PERL Extention.

=head1 SYNOPSIS

  use OpenCA::Tools;

=head1 DESCRIPTION

This module provides some tools to easy some standard actions. Current
functions description follows:

	new		- Returns a reference to the object.
	getDate		- Returns a Printable date string.
	copyFiles	- Copy file(s).
	moveFiles	- Move file(s).
	deleteFiles	- Delete file(s).
	cmpDate		- Compare two Printable date sting.
	isInsidePeriod	- Check wether give date is within given
			  period.
	parseDN         - Parse a given DN returning an HASH value.

=head1 FUNCTIONS

=head2 sub new () - Build new instance of the class.

	This function returns a new instance of the class. No parameters
	needed.

	EXAMPLE:
	
		my $tools = new OpenCA::Tools();

=head2 sub getDate () - Get a Printable date string.

	Returns a string representing current time (GMT or Local).
	Accepted parameters are:

		FORMAT  - Use it to get local or GMT time.
			  Defaults to GMT.

	EXAMPLE:

		print $tools->getDate();

=head2 sub copyFiles () - Copy file(s).

	Use this function to copy file(s). Source path can contain
	wildcards (i.e. '*') that will be expanded when copying.
	Accepted parameters are:

		SRC  - Source full path.
		DEST - Destination path.

	EXAMPLE:

		$tools->copyFiles( SRC=>"test.pl", DEST=>"/tmp" );

=head2 sub moveFiles () - Move file(s).

	Use this function to move file(s). Source path can contain
	wildcards (i.e. '*') that will be expanded when copying.
	Accepted parameters are:

		SRC  - Source full path.
		DEST - Destination path.

	EXAMPLE:

		$tools->moveFiles( SRC=>"test.pl", DEST=>"/tmp" );

=head2 sub deleteFiles () - Delete file(s).

	Use this function to delete file(s) once provided target
	directory and filter.
	Accepted parameters are:

		DIR    - Directory containing file(s) to delete.
		FILTER - File filtering(*).

	(*) - Optional parameters;

	EXAMPLE:

		$tools->deleteFiles( DIR=>"/tmp", FILTER=>"prova.p*" );

=head2 sub cmpDate () - Compare two date strings.

	Use this function to get informations on relationship
	between the two provided date strings. Returns integer
	values like strcmp() do in C, so if DATE_1 'is later'
	than DATE_2 it returns a positive value. A negative value
	is returned in the countrart case while 0 is returned if
	the two dates are equal. Accepted parameters:

		DATE_1  - First date string.
		DATE_2  - Second date string.

	EXAMPLE:

		$tools->cmpDate( DATA_1=>"$date1", DATA_2=>"$date2" );

=head2 sub isInsidePerios - Check if date is inside a given period.

	This functions returns a true (1) value if the provided
	date is within a given period. Accepted parameters are:

		DATE     - Date string to check.
		START	 - Date string indicating period's starting(*).
		END      - Date string indicating period's ending(*).

	(*) - Optional parameters;

		if( not $tools->isInsidePeriod( DATE=>$d1, START=>$d2,
				END=>$d3 ) ) {
			print "Non in period... \n";
		}

=head2 sub parseDN () - Parse a given DN.

	This function parses a given DN string and returns an HASH
	value. Returned structure is as following:

		KEY => VALUE,

	Only the OU key is instead a list:

		OU => [ @list ]

	EXAMPLE:

		$parsed = $tools->parseDN( $dn );
		print $parsed->{CN};

		foreach $tmp ( @{ $parsed->{OU} } ) {
			print "OU=$tmp\n";
		}

=head1 AUTHOR

Massimiliano Pala <madwolf@openca.org>

=head1 SEE ALSO

OpenCA::Configuration, OpenCA::TRIStateCGI, OpenCA::X509, OpenCA::CRL, OpenCA::REQ, OpenCA::OpenSSL, perl(1).

=cut
