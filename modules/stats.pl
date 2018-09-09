#--------------------------------------------------------------
# NAG - Net.Art Generator
#
# Author: Panos Galanis <pg@iap.de>
# Created: 16.04.2003
# Last: 10.06.2003
# License: GNU GPL (GNU General Public License. See LICENSE file)
#
# Copyright (C) 2003 IAP GmbH
# Ingenieurb¸ro f¸r Anwendungs-Programmierung
# Mˆrkenstraﬂe 9, D-22767 Hamburg
# Web: http://www.iap.de, Mail: info@iap.de 
#--------------------------------------------------------------
#
#--------------------------------------------------------------
# NAG - Net.Art Generator (updated version as of 2018)
#
# Co-Author: Winnie Soon <rwx[at]siusoon.net>
# Last: 09.09.2018
# Web: www.siusoon.net
#
# 1. Updated the limits as suggested by iap: 50 to 500 MB for carch and 500 to 5000 for generated images 
#--------------------------------------------------------------
# Satistics Module
#

use File::Copy;

my $fstat= "./stats/statfile.txt";
my $flast= "./stats/last.txt";

sub clickStat {
	my $rec=shift;
	my $r,$c,$f,$l,$fr,$fc,$ff,$fl,$found,@list;
	open(FH, "+<$fstat") || die "I can't Open $fstat :$!\n";
	#open(FH, "+<:encoding(UTF-8)", $fstat) || die "I can't Open $fstat :$!\n";
	@list=<FH>;
	close(FH);
	#open(FH, "+<:encoding(UTF-8)", $fstat) || die "I can't Open $fstat :$!\n";
	open(FH, ">$fstat") || die "I can't Open ~$fstat :$!\n";
	foreach (@list) {
		$_ =~ s/[\r\n]//g;
		($r,$c,$f,$l) = split(m/∞/, $_);
		if ($rec eq $r) {
			$found=1;
			$c++;
			$fr=$r; $fc=$c; $ff=$f; $fl=time;
			print FH "$fr∞$fc∞$ff∞$fl\n";
			} else {
			print FH "$r∞$c∞$f∞$l\n";
			}
		}
	if (!$found) {
		$r=$rec;
		$c=1;
		$f=$l=time;
		$fr=$r; $fc=$c; $ff=$f; $fl=time;
		print FH "$r∞$c∞$f∞$l\n";
		}
	close(FH);
    #move("$fstat.back","$fstat") == 1 or die "Error::While moving : $!";
	open(FH, ">$flast") || die "I can't Open $flast :$!\n";
	print FH "$ENV{'REMOTE_ADDR'}∞$ENV{'HTTP_REFERER'}∞$ENV{'REQUEST_URI'}";
	close(FH);
    #print "[DBG::ClickStat::($c,$f,$l)]";
	return ($fc,$ff,$fl);

	}

sub getStat {
	my $rec=shift;
	if (!-e "$fstat"){
		return (0, 0, 0);
		}
	open(FH, "$fstat") || die "I can't Open $fstat :$!\n";
	while (<FH>) {
		$_ =~ s/[\r\n]//g;
		my ($r,$c,$f,$l) = split(m/∞/, $_);
		if ($rec eq $r) {
			close(FH);
			return ($c,$f,$l);
			}
		}
	close(FH);
	return (0, 0, 0);
	}

sub getStatTop {
	my $no=shift;
	return () if (!-e "$fstat");
	my @REC,@lim;
	open(FH, "$fstat") || die "I can't Open $fstat :$!\n";
	while (<FH>) {
		chop if (m/\n/);
		my ($r,$c,$f,$l) = split(m/∞/, $_);
		push(@REC, [$r,$c,$f,$l]);
		}
	close(FH);
	@REC=sort { @$b[1] cmp @$a[1] } @REC;
	foreach (my $i=1; ($i<=$no && @REC > 0); $i++) {
		push(@lim, shift(@REC));
		}
	return @lim;
	}

sub getLast {
	my $no=shift;
	return () if (!$no);
	#opendir(DIR, "gen/") || die "I Can't Opendir [gen/] : $!\n";
	opendir(DIR, "./gen/") || die "I Can't Opendir [gen/] : $!\n";

	my @list=readdir(DIR);
	closedir(DIR);

	my @REC,@lim;
	@REC=@lim=();
	foreach (@list) {
		if ($_ !~ m/^\.{1,2}/) {
			my ($f,$d) = ($_, (stat("./gen/$_"))[9]);
			push(@REC, [$f,$d]);
			}
		}
	@REC=sort { @$b[1] cmp @$a[1] } @REC;
	foreach (my $i=1; ($i<=$no && @REC > 0); $i++) {
		push(@lim, shift(@REC));
		}
	return @lim;
	}

sub isLast {
	my $rec="$ENV{'REMOTE_ADDR'}∞$ENV{'HTTP_REFERER'}∞$ENV{'REQUEST_URI'}";
	return -1 if (!-e "$flast");
	open(FH, "$flast") || die "I can't Open $flast :$!\n";
	@lines=<FH>;
	close(FH);
	$lines[0] =~ s/[\r\n]//;
	return 1 if ($lines[0] eq $rec);
	return 0;
	}

sub clearOldies {
	#Get the statistics file.
	my @STAT, @list, @GEN, @GRAB, $max, $GEN_sum, $GRAB_sum, $smax, $maxcache;
	$GEN_sum=$GRAB_sum=0;
	$max=5000*1024*1024; # 5000 Mb for Generated
	$maxcache=500*1024*1024; # 500 Mb for Cache
	$smax=140; # Keep the <number> first photos from the statistic file
	open(FH, "$fstat") || die "I can't Open $fstat :$!\n";
	while (<FH>) {
		$_ =~ s/[\r\n]//g;
		my ($r,$c,$f,$l) = split(m/∞/, $_);
		push(@STAT, [$r,$c,$f,$l]);
		}
	close(FH);

	opendir(DIR, "./gen/") || die "I Can't Opendir [gen] : $!\n";
	@list=readdir(DIR);
	closedir(DIR);

	foreach (@list) {
		if ($_ !~ m/^\.{1,2}/) {
			$GEN_sum += (stat("./gen/$_"))[7];
			push(@GEN, [$_, (stat("./gen/$_"))[7],(stat("./gen/$_"))[9]]);
			}
		}

	opendir(DIR, "./grab/") || die "I Can't Opendir [grab] : $!\n";
	@list=readdir(DIR);
	closedir(DIR);

	foreach (@list) {
		if ($_ !~ m/^\.{1,2}/) {
			$GRAB_sum += (stat("./grab/$_"))[7];
			push(@GRAB, [$_, (stat("./grab/$_"))[7],(stat("./grab/$_"))[9]]);
			}
		}

	# Sort the lists (Older first)
	@STAT=sort { @$a[1] cmp @$b[1] } @STAT;
	@GEN=sort { @$a[2] cmp @$b[2] } @GEN;
	@GRAB=sort { @$a[2] cmp @$b[2] } @GRAB;

	# Save Click sorted list...
	open(FH, ">$fstat") || die "I can't Open $fstat :$!\n";
	foreach (reverse @STAT) {
	    print FH "@$_[0]∞@$_[1]∞@$_[2]∞@$_[3]\n" if @$_[0];
	    }
	close(FH);

	# Don't protect more than ($smax=40)
	while (@STAT > $smax) { shift(@STAT); }

	#print "<hr>";
	#foreach (reverse @STAT) { print "(@$_[1]) @$_[0]<br>\n";}
	#print "<hr>\n";

	my $cache_no, $no, $csize, $ldate, $ldate_cache;
	$del=$all=$no=$cache_no=$csize=0;
	my $nodel,$stat,@dlist;
	#
	# Clear Image Cache > 30 MB
	foreach (@GRAB) {
		if ($GRAB_sum > $maxcache) {
			$GRAB_sum -= @$_[1];
			$csize += @$_[1];
			$ldate_cache = @$_[2];
			$cache_no++;
			if (-e "./grab/@$_[0]") {
			    $del += unlink("./grab/@$_[0]");
			    }
			}
	    }
	#
	# Clear Generated Images
	# Older first, > 40 MB
	foreach (@GEN) {

	    # Clear without question Generator errors if any!
	    # ex. no Image or if < 1024 bytes
		if (-e "./gen/@$_[0]" && (@$_[0] !~ /\.(gif|jpeg|jpg|png)$/i || (stat("./gen/@$_[0]"))[7] < 1024)) {
			$del += unlink("./gen/@$_[0]");
    		if (-e "./thumb/@$_[0]") {
			    $del += unlink("./thumb/@$_[0]");
			    }
    		}

        # Look if this Image is in TOP clicked list
        # ($smax=40) and protect if so.
	    $nodel=0;
	    foreach $stat (@STAT){
	        $nodel=1 if @$_[0] eq @$stat[0];
	        }
    	#push(@dlist, "### @$_[0] ### Protected!") if ($is > $max && $nodel);

    	# Clear
    	#
		if ($GEN_sum > $max && !$nodel) {
			$GEN_sum -= @$_[1];
			$csize += @$_[1];
			$ldate = @$_[2];
			$no+=2;
			if (-e "./thumb/@$_[0]") {
				$del += unlink("./thumb/@$_[0]");
				}
			if (-e "./gen/@$_[0]") {
				$del += unlink("./gen/@$_[0]");
				#push(@dlist, "gen/@$_[0]");
				#$del+=2;
				}
			# print "*** ";
			} # if ($GEN_sum > $max && !$nodel)
		#print "(". ++$cno .") @$_\n";
		} # foreach (@GEN)
	#print "<hr>NOW -- IS: $is MAX: $max<hr>\n";
	#print "<hr>". join ("<br>",@dlist) ."<hr>";
	my $res = "[ $cache_no / $no / $del ] "; # Cache, Gen, Del
	$res .= sprintf "%.2f kb", $csize/1024;
	#$res .= " :: Last C_Date: ". localtime($ldate_cache) if $ldate_cache;
	$res .= " :: Last ". localtime($ldate) if $ldate;
	return $res;
	}

1;
