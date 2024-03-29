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

$OpenCA::Tools::VERSION = '0.4.3';

use FileHandle;
our ($STDERR, $STDOUT);
$STDOUT = \*STDOUT;
$STDERR = \*STDERR;

our ($errno, $errval);

sub new {
	my $that = shift;
	my $class = ref($that) || $that;

	my $self = {};
	bless $self, $class;

        my $keys = { @_ };
        if (scalar @_ == 1) {
            return undef if (not $self->setXMLConfig ($_[0]));
        } elsif (scalar @_ > 1) {
            if ($keys->{CONFIG}) {
                return undef if (not $self->setXMLConfig ($keys->{CONFIG}));
            } elsif ($keys->{CONFIGURATION}) {
                return undef if (not $self->setXMLConfig ($keys->{CONFIGURATION}));
            }
        }

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
        my $fileName = shift;

        my ( $ret, $temp );

        open( FD, $fileName ) || return;
        while ( $temp = <FD> ) {
                $ret .= $temp;
        };
        close FD;
        return $self->getConfiguredData ($ret);
}

sub saveFile {
        my $self = shift;
        my $keys = { @_ };

	my $fileName = $keys->{FILENAME};
	my $data     = $keys->{DATA};

        open( FD, ">$fileName" ) || return;
		print FD $data;
	close(FD);

	return 1;
}

sub copyFiles {
	my $self = shift;
	my $keys = { @_ };

	my $src = $keys->{SRC};
	my $dst = $keys->{DEST};
	my $md  = $keys->{MODE};

	my @fileList = glob("$src");
	my ( @tmp, $tmpDst, $line, $file, $fileName );

	print "OpenCA::Tools: copyFiles<br>\n" if ($self->{DEBUG});
	print "OpenCA::Tools: src = $src<br>\n" if ($self->{DEBUG});
	print "OpenCA::Tools: fileList = ".join (",", @fileList)."<br>\n" if ($self->{DEBUG});
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
		
		print "OpenCA::Tools: variables defined to copy a file (from $file to $tmpDst)<br>\n" if ($self->{DEBUG});
		open( FD, "<$file" ) or return;
		print "OpenCA::Tools: $file was opened for reading<br>\n" if ($self->{DEBUG});
		open( DF, ">$tmpDst" ) or return;
		print "OpenCA::Tools: $tmpDst was opened for writing<br>\n" if ($self->{DEBUG});
			while( $line = <FD> ) {
				print DF $line;
			}
		close(DF);
		close(FD);
		print "OpenCA::Tools: copying completed<br>\n" if ($self->{DEBUG});

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

sub setXMLConfig {

    my $self = shift;

    if (scalar @_ == 2) {
       my $keys = { @_ };
       $self->{xml_config} = $keys->{CONFIG}        if ($keys->{CONFIG});
       $self->{xml_config} = $keys->{CONFIGURATION} if ($keys->{CONFIGURATION});
    } elsif (scalar @_ == 1) {
       $self->{xml_config} = $_[0];
    } else {
       $self->setError (5171010, "OpenCA::TRIStateCGI->setXMLConfig was used with an uncorrect".
                                 " number of arguments.");
       return undef;
    }

    return 1;
}

sub loadXMLConfig {

    my $self = shift;

    use XML::Twig;
    $self->{twig} = new XML::Twig;
    if (not $self->{twig})
    {
        $self->setError (5173010, "XML::Twig cannot be created");
        return undef;
    }

    if (not $self->{twig}->safe_parsefile($self->{xml_config}))
    {
        $self->setError (6231020, "XML::Twig cannot parse configuration file ".$self->{xml_config}.".".
                                  "XML::Parser returned errormessage: ".$@);
        return undef;
    }

    return 1;
}

sub getConfiguredData {

    my $self = shift;
    my $data = "";

    ## get data
    if (scalar @_ == 2) {
       my $keys = { @_ };
       $data = $keys->{DATA};
    } elsif (scalar @_ == 1) {
       $data = $_[0];
    } else {
       $self->setError (5175010, "OpenCA::TRIStateCGI->getConfiguredData was used with an uncorrect".
                                 " number of arguments.");
       return undef;
    }

    ## load configuration
    return $data if (not $self->{xml_config});
    return undef if (not $self->{twig} and not $self->loadXMLConfig());

    ## check for software configuration
    if (not $self->{twig}->get_xpath ('software_config')) {
        $self->setError (5175020, "There is no software configuration in the XML configuration file.");
        return undef;
    }

    ## check for prefix and suffix
    if (not $self->{twig}->get_xpath ('software_config/prefix')) {
        $self->setError (5175023, "There is no prefix in the software configuration of the XML configuration file.");
        return undef;
    }
    if (not $self->{twig}->get_xpath ('software_config/suffix')) {
        $self->setError (5175026, "There is no suffix in the software configuration of the XML configuration file.");
        return undef;
    }

    ## load prefix and suffix
    $self->{option_prefix} = ($self->{twig}->get_xpath ('software_config/prefix'))[0]->field;
    $self->{option_suffix} = ($self->{twig}->get_xpath ('software_config/suffix'))[0]->field;
    my $prefix = $self->{option_prefix};
    my $suffix = $self->{option_suffix};

    ## translate data
    foreach my $option ($self->{twig}->get_xpath('software_config/option'))
    {
        ## check for a name and value
        if (not $option->first_child ('name')) {
            $self->setError (5175033, "There is no name for an option of the software configuration ".
                                      "of the XML configuration file.");
            return undef;
        }
        if (not $option->first_child ('value')) {
            $self->setError (5175036, "There is no value for an option of the software configuration ".
                                      "of the XML configuration file.");
            return undef;
        }

        ## replace the options in the data
        my $name  = $option->first_child ('name')->field;
        my $value = $option->first_child ('value')->field;
        $value = $option->first_child ('value')->first_child->sprint
            if ($option->first_child ('value')->first_child);
        $data =~ s/${prefix}${name}${suffix}/${value}/sg;
    }

    return $data;
}

sub setError {
    my $self = shift;

    if (scalar (@_) == 4) {
        my $keys = { @_ };
        $errval = $keys->{ERRVAL};
        $errno  = $keys->{ERRNO};
    } else {
        $errno  = $_[0];
        $errval = $_[1];
    }

    print $STDERR "PKI Master Alert: Access control is misconfigured\n";
    print $STDERR "PKI Master Alert: Aborting all operations\n";
    print $STDERR "PKI Master Alert: Error:   $errno\n";
    print $STDERR "PKI Master Alert: Message: $errval\n";
    print $STDERR "PKI Master Alert: debugging messages of access control follow\n";
    $self->{debug_fd} = $STDERR;
    $self->debug ();
    $self->{debug_fd} = $STDOUT;

    ## support for: return $self->setError (1234, "Something fails.") if (not $xyz);
    return undef;
}

sub debug {

    my $self = shift;
    if ($_[0]) {
        $self->{debug_msg}[scalar @{$self->{debug_msg}}] = $_[0];
        $self->debug () if ($self->{DEBUG});
    } else {
        my $msg;
        foreach $msg (@{$self->{debug_msg}}) {
            $msg =~ s/ /&nbsp;/g;
            my $oldfh = select $self->{debug_fd};
            print $STDOUT $msg."<br>\n";
            select $oldfh;
        }
        $self->{debug_msg} = ();
    }

}

#############################################################################
##                         check the channel                               ##
#############################################################################
# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
