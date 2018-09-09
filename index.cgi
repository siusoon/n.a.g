#!/usr/bin/perl
#--------------------------------------------------------------
# NAG - Net.Art Generator
#
# Author: Panos Galanis <pg@iap.de>
# Created: 16.04.2003
# Last: 10.06.2003
# License: GNU GPL (GNU General Public License. See LICENSE file)
#
# Copyright (C) 2003 IAP GmbH 
# Ingenieurbüro für Anwendungs-Programmierung
# Mörkenstraße 9, D-22767 Hamburg
# Web: http://www.iap.de, Mail: info@iap.de 
#--------------------------------------------------------------

#--------------------------------------------------------------
# NAG - Net.Art Generator (updated version as of 2017)
#
# Co-Author: Winnie Soon <rwx[at]siusoon.net>
# Last: 9.09.2018
# Web: www.siusoon.net
#
# 1. fixed Google search API: request, retrieval, parsing of image search and error code checking
# 2. add Flattr and change the wordings
# 3. remove DE language and add the home navigation button (retain original de message in the source code)
# 4. remove gif option as animation is not supported
# 5. support other non-english language and characters such as German, Danish, Japanese and Chinese
# 6. remove 1000 max width as tested with no different with the others
# 7. change from http to https for security reasons as per iap suggestions
#--------------------------------------------------------------

use strict;
use CGI;
use CGI::Carp 'fatalsToBrowser';
use LWP::UserAgent;
use Image::Magick;
use POSIX;
use HTTP::Request;

use JSON;
use JSON::Parse;
use warnings;
use Encode;

my $q = new CGI;
my @ilinks;
my @err;
my $comment="<!--
# NAG - Net.Art Generator
#
# Author : Panos Galanis info\@iap.de
# Using : Perl v". sprintf("%vd", $^V) .", LWP::UserAgent v". $LWP::UserAgent::VERSION .", ImageMagick v". $Image::Magick::Q16::VERSION ."
#
# This is published under the GNU General Public License (GPL)
# see http://www.opensource.org/licenses/gpl-license.php

# Ingenieurb¸ro f¸r Anwendungs-Programmierung GmbH         
# Mˆrkenstraﬂe 9, D-22767 Hamburg                      
# Web: http://www.iap.de, Mail: info\@iap.de
-->
<!--
# NAG - Net.Art Generator (updated version with Google API fixed + others)
#
# Co-Author: Winnie Soon <rwx[at]siusoon.net>
# Last: 11.12.2017
# Using : JSON v". $JSON::VERSION .", JSON::Parse v". $JSON::Parse::VERSION ."
#
# Web: www.siusoon.net
-->
";

POSIX::nice(int(rand(15)+4));

# $kunst=~ s/[^\w\d]/_/i;

require "./modules/display.pl";
require "./modules/netagent.pl";
require "./modules/imageagent.pl";
require "./modules/stats.pl";

# Parameter Security
my $ac=($q->param('ac'))?$q->param('ac'):"";
my $single=($q->param('file'))?$q->param('file'):"";
my $name=($q->param('name'))?$q->param('name'):"anonymous";
my $query=($q->param('query'))?$q->param('query'):"";
my $max=($q->param('max'))?$q->param('max'):0;
my $ext=($q->param('ext'))?$q->param('ext'):"";
my $comp=($q->param('comp'))?$q->param('comp'):0;
my $picas=($q->param('picas'))?$q->param('picas'):"";
my $picmax=($q->param('picmax'))?$q->param('picmax'):0;
my $noclick=($q->param('noclick'))?1:0;
my $lang=($q->param('lang'))?$q->param('lang'):"en";
$ac=&secCheck($ac,"home","display","create","single","TOP10");
$max=&secCheck($max,600,400,800);
$ext=&secCheck($ext,"jpg","png");
$comp=&secCheck($comp,4,2,6,8);
$lang=&secCheck($lang,"de","en");


# Parameter Security

print "Content-type: text/html\n\n";
#print "$name - $query - $max - $ext - $comp";
print $comment;
print &startPage(ucfirst($ac) ." ", $lang);
#print &startPage("net.art generator : nag_05");
print &startPanel("<b>.:: NAG :: Net.Art Generator</b>");
my $pext;
foreach ($q->param()) {
    $pext .= "\&$_=". $q->param($_) if ($_ ne "lang");
    }
$pext .="&noclick=1" if ($single && !$noclick);
#print "[$pext]";
print &rowTabs(
		"#cccccc","","left", #bgcolor, font_color, alignment
		($lang eq "de")? "Start":"Home", ($ac eq "home")? "":"/?lang=$lang",
#		($lang eq "de")? "Archiv":"Display", ($ac eq "display")? "":"?ac=display\&lang=$lang",
		($lang eq "de")? "Erzeugen":"Create", ($ac eq "create")? "":"?ac=create\&lang=$lang",
		($lang eq "de")? "TOP 10":"TOP10", ($ac eq "TOP10")? "":"?ac=TOP10\&lang=$lang",
		#($lang eq "de")? "English":"Deutsch", ($lang eq "de")? "?lang=en$pext":"?lang=de$pext"
		($lang eq "de")? "nag_home":"nag_home", ($lang eq "de")? "http://net.art-generator.com/":"http://net.art-generator.com/"  #I did a trick here without modifying much code with just EN version retained. As a result, all the previous code on DE ver is retained.
		);
print &endPanel;

if ($ac eq "home") {
	print &startPanel("<b>Willkommen beim Netzkunstgenerator!</b>") if ($lang eq "de");
	print &startPanel("<b>Welcome to NAG</b>") if ($lang eq "en");

	print "<p>Der Netzkunstgenerator dient zur automatischen Produktion von Netzkunst auf Bestellung.</p>
<p>Die vorliegende Version des Generators stellt Bilder her. Das neu entstehende Bild geht als eine Art Collage aus den im WWW gefundenen Bildern hervor, die nach der Eingabe Ihres 'Titles' von einer Suchmaschine angezeigt worden sind. Das Originalmaterial wird in 12-14 zufallsgesteuerten Schritten verarbeitet und neu kombiniert.</p>
<p>Dieser Netzkunstgenerator wurde von Panos Galanis von der Firma IAP GmbH, Hamburg, in Zusammenarbeit mit Cornelia Sollfrank programmiert und war eine Auftragsarbeit der Volksf�rsorge Kunstsammlung.</p>
<p>Falls es bei der Handhabung Probleme geben sollte oder der Generator nicht funktioniert, wenden Sie sich bitte an:
IAP &lt;<a href=\"mailto:info\@iap.de?Subject=NAG::Mail\">info\@iap.de</a>&gt;
oder Cornelia &lt;<a href=\"mailto:cornelia\@snafu.de?Subject=NAG::Mail\">cornelia\@snafu.de</a>&gt;</p>
<p>Viel Spass beim Kunstmachen!</p>
<p>Besuchen Sie auch <a href=\"http://net.art-generator.com\" TARGET=\"_blank\">net.art-generator.com</a> f&uuml;r mehr Informationen zu den Netzkunstgeneratoren.</p>
" if ($lang eq "de");

	print "<p>The net.art generator automatically produces net.art on demand.</p>
<p>nag_05-this version of the net.art generator creates images. The resulting image emerges as a collage of a number of images which have been collected on the WWW in relation to the 'title' you have chosen. The original material is processed in 12-14 randomly chosen and combined steps. For finding the images, nag_05 draws on Google search; that is the delicate part as Google limits access to their search results for all non-paying clients including net.art projects like this one.</p>
<p>The technical base of the net.art generator is a PERL script, old but reliable technology. The original version was programmed by Panos Galanis from IAP GmbH, Hamburg, in 2003 after an idea by net.artist Cornelia Sollfrank. With Winnie Soon, the net.art generator has found a skillful new master of creative coding in 2017. </p>
<p>We need your feedback to develop the project further! Please tell us about your experiences related to the nag. We would like to know what is happening on the other end! Also, if you are facing problems regarding the functionality, please contact <a href=\"mailto:nag\@artwarez.org?Subject=NAG::Mail\">nag[at]artwarez.org</a>.
<p>If you would like to support the ongoing development and search requests of _nag, you can <a href=\"https://flattr.com/submit/auto?fid=ljw0go&url=http%3A%2F%2Fnag.iap.de%2F\" target=\"_blank\"><img src=\"//button.flattr.com/flattr-badge-large.png\" alt=\"Flattr this\" title=\"Flattr this\" style=\"vertical-align:middle\" border=\"0\"></a> us!</p>
<p>Have fun and become a net.artist!</p>
<p>For more information, please visit <a href=\"http://net.art-generator.com\" TARGET=\"_blank\">net.art-generator.com</a>, the home of all net.art.generators!
<p>Many thanks to the generous support by IAP GmbH, in particular Gerrit Ch&eacute; Boelz for his enthusiasm and dedication. </p>
"if ($lang eq "en");

	print &endPanel;
	print &startPanel("<b>Screenshot</b>");
	print "<p align='center'><img src='./img/gen_shot_01_small.gif' class='ipreview' alt='Screenshot' /> \n";
	print "<img src='./img/gen_shot_02_small.gif' class='ipreview' alt='Screenshot' /> \n";
	print "<img src='./img/gen_shot_03_small.gif' class='ipreview' alt='Screenshot' /> </p>\n";
	print &endPanel;
	}
if ($ac eq "display") {
	#push(@err, "Warn :: Generator parameters require <b>Query</b> input !!") if ($max && !$query && !$picas) ;
	print &startPanel("Display Generated Pictures") if ($lang eq "en");
	print &startPanel("Bilder-Archiv anschauen") if ($lang eq "de");
	print "<form method='get' action='/'><table><tr><td nowrap>";
	foreach ("a".."z") {
		print "<a href=\"/?ac=display&lang=$lang&picas=-[$_". uc($_) ."]\">$_</a> \n";
		}
	my ($gsize,@glist)=&getDirInfo("./gen/");
	$gsize = ($gsize > 1024*1024)? sprintf("%.2f Mb", $gsize/(1024*1024)) : sprintf("%.2f kb", $gsize/1024);
	print "</td><td width='99%' align='right'><b>";
	print "". ($lang eq "en")? "Search":"Suchen";
	print "</b> ". @glist ." ";
	print "". ($lang eq "en")? "pictures":"Bilder";
	print " ($gsize) </td><td nowrap>";
	print "<input type='hidden' name='ac' value='display' /><input type='text' name='picas' value='$picas' /> ";
	print "<input type='submit' value='Search' /></td></tr></table></form>\n";
	#print "<p align='center'>\n";
	if ($picas) {
		my @tmp;
		foreach (@glist) {
			push(@tmp, $_) if (m/$picas/i);}
		@glist=@tmp;
		}
	$picmax=(@glist < 20)? @glist : 20;
	my @rfiles = &randImgList($picmax, @glist);
	my ($mt,$ctd,$myf)=(0,0,"");
	foreach $myf (@rfiles) {
		if (!-e "./thumb/$myf"){
			push(@err, &makeThumb(120, $myf));
			$mt++;
			}
		#my ($c,$f,$l)=&getStat($myf);
		if (!$ctd) { $ctd++; print "\n<table width='100%'>\n<tr>"; }
		if ($ctd > 4 ) { $ctd=1; print "</tr>\n<tr>"; }
		print "<td align='center' class='small'>";
		print "<a href=\"?ac=single&lang=$lang&file=$myf\"><img src=\"./thumb/$myf\" title='$myf' vspace='10' hspace='10' class='ipreview' alt='$myf'/></a>\n";
		my ($ti,$da)=split(m/\@/, $myf);
		my @d=split(m/_+/, $da);
		print "<br />$ti <br />\@ $d[0] $d[1] $d[2]";
		print "</td>";
		$ctd++;
		}
	print "</tr></table>";
	#print "</p>\n";
	print &endPanel;
	print "<small>Display ". @rfiles ." Thumbs :: $mt Updates.</small>\n";
	}

elsif ($ac eq "create") {
	print &startPanel("Info");

	print "The generation of your piece of net.art takes 1-2 minutes. Please have a
little patience. If nothing has happenend after 2 minutes, please click
the 'stop'-button and try again.
" if ($lang eq "en");

	print "Die Erzeugung Ihres net.art-Bildes ben�tigt ein bis zwei Minuten. Bitte
haben Sie etwas Geduld. Wenn nach zwei Minuten noch nichts passiert ist, dann dr�cken
Sie den Stop-Knopf und versuchen Sie es noch ein mal.
" if ($lang eq "de");

#------Soon's modification start-------------
	print &endPanel;
	print &startPanel(($lang eq "en")?"Query":"Abfrage");
	print &inputForm($name,$query,$max,$ext,$comp);
	print &endPanel;

	#if ($name && $query && $query =~ /[\w\s]+/i) {	#ver1
	if ($name && $query && $query =~ /[.*]*/i) {   #ver2: support other lang query
		my @dt=split(" ", localtime(time));
		shift(@dt);
		my $imfile = $name ."-". $query ."@". join(" ", @dt);
		#$imfile =~ s/[^\w\d\@\-\:]/_/g;  #ver1: not support other language
		$imfile =~ s/[^\W\w\d\@\-\:]/_/g; #ver2: support other lang
		#$imfile =~ s/[\?\s\,\']/_/g; #can't have ?, space,' and comma in a file name
    $imfile =~ s/[\?\s\≈\∞\≤\Ω\,\']/_/g; #can't have ?, space,' and comma in a file name
		$imfile =~ s/\:/\./g;

		print &startPanel("Searching the Net for <em>$query</em> :: Powered by <a href='https://www.google.com/imghp'>Google</a>");
		my @ilist=&getImgList($query, $ext);
		if (!@ilist) {
			push(@err,"Query [$query] returned no Images! Please try again.");
			print "<center>Generator process canceled!</center>\n";
			print &endPanel;
		}else{
			if ($ilist[0] eq "dailyLimitExceeded"){  #dailyLimitExceeded - msg by Google
		    	push(@err,"<p>Thanks for using nag_05! Unfortunately, it seems as if the limit of queries for today is already exceeded! </p>
<p>Due to current Google policies, access to search results is very limited for non-paying customers like this wonderful net.art project (100 requests
per day)!</p>
<p>We do our best to keep the _nag alive, but there is no funding to pay for
Google, so please be patient and come back tomorrow. </p>
<p>If you would like to support the ongoing development and search requests
of _nag, you can flattr us! </p>
<p>In the long run, we are working on teaching Google about how they can
support art on the Internet in a meaningful way, but there is still a long
way to go ;-) </p>");
		    	print "<center>Generator process canceled!</center>\n";
				print &endPanel;
			}else{
				my @mylist=&randImgList($comp,@ilist);
				print "Choosing  : ". @mylist . " / ". @ilist ."<br />\n";
				print "<ul>\n" if @mylist;
				foreach (@mylist) { print "<li>$_ :: <a href='$_' target='_blank'>view</a></li>\n"; }
				print "</ul>\n" if @mylist;
				print &endPanel;
				print &startPanel("Generator Usage");
				my @localist=&grabImg(@mylist);
				my $cached=shift(@localist);
				print "<p>Composition ". @localist . " :: New ". (@localist - $cached) ." :: Cached $cached";
				print &endPanel;
				print &startPanel("Show");
				my $base=shift(@localist);
				push(@err, &genImg($imfile, $max, $max, $ext, $base, @localist));
				push(@err, &makeThumb(120, "$imfile.$ext"));
				print "<center><img src='./gen/$imfile.$ext' title='$imfile' class='ipreview' /><br /><b>$imfile</b></center>";
				print &endPanel;
				my $res=&clearOldies;
				print "<small>Cleaner :: $res </small>";
			}
		}
	}else{
		push(@err,"No Artist ??") if (!$name);
		push(@err,"Query [$query] not accepted!") if ($query && $query !~ /[\w\s]+/i);
	}
}

#------Soon's modification end-------

elsif ($ac eq "single") {
	if (-e "./gen/$single") {
		my ($c, $f, $l);
		($c, $f, $l)=(&isLast || $noclick)? &getStat($single):&clickStat($single);
		print &startPanel("Display Single File :: <b>$c</b> click(s) :: <b>". localtime($l) . "</b> last one");
		print "<center><img src='./gen/$single' border='0' class='ipreview' /><br /><a href='./gen/$single'>$single</a></center>";
		print &endPanel;
		}else{
		push(@err, "File :: $single :: Not found ????");
		}
	}

elsif ($ac eq "TOP10") {
		my ($size,@clist)=&getDirInfo("./grab/");
		$size = ($size > 1024*1024)? sprintf("%.2f Mb", $size/(1024*1024)) : sprintf("%.2f kb", $size/1024);
		my ($gsize,@glist)=&getDirInfo("./gen/");
		$gsize = ($gsize > 1024*1024)? sprintf("%.2f Mb", $gsize/(1024*1024)) : sprintf("%.2f kb", $gsize/1024);
		print &startPanel("Picture Base Status");
		print "Net Cached: ". @clist ." ($size)";
		print " :: Generator: ". @glist ." ($gsize)</p>\n";
		print &endPanel;
		print &startPanel("Statistics <b>Top 10</b>");
		print "<table width='100%' cellspacing='1'>\n";
		my $cl=0;
		my $top;
		my ($dif,$no);
	    foreach $top (&getStatTop(10)) {
			$no++;
			if (!$cl) { print "<tr>";  }
			#$dif=($dif eq "#dddddd")? "#eeeeee" : "#dddddd";  #
			$dif = "#dddddd";
			my ($ti,$da)=split(m/\@/, @$top[0]);
			my @d=split(m/_+/, $da);
			print "<td valign='top' bgcolor='$dif'>";
			print "<a href='?ac=single&file=@$top[0]&noclick=1'><img src='./thumb/@$top[0]' border='1' vspace='4' hspace='4' class='ipreview'/></a></td>";
			print "<td bgcolor='$dif'><font size='+2'>$no</font><br />\n";
			print "<b>$ti </b><br />\@ $d[0] $d[1] $d[2]<br />";
			print "<br /><b>@$top[1]</b> click(s) <br />First click: ". localtime(@$top[2]) ." <br /> last: ". localtime(@$top[3]);
			print "</td>";
			if ($cl >= 1) {	print "</tr>\n"; $cl=0; }else{ $cl++; }
			}
		print "</table>\n";
		print "<center>Empty Statistics table!</center>\n" if (!$no);
		print &endPanel;

		print &startPanel("Statistics <b>Last 10</b>");
		print "<table width='100%' cellspacing='1'>\n";
		my $last;
		$no=$cl=0;
		foreach $last (&getLast(10)) {
			$no++;
			if (!$cl) { $cl++; print "\n<tr>";  }
			my ($ti,$da)=split(m/\@/, @$last[0]);
			my @d=split(m/_+/, $da);
			print "<td align='center' class='small'>";
			print "<a href='?ac=single&file=@$last[0]'><img src='./thumb/@$last[0]' title='@$last[0]' vspace='10' hspace='10' class='ipreview' /></a>\n";
			#print "<br />$ti <br />\@ $d[0] $d[1] $d[2]";
			@$last[0] =~ s/\D{4}$//;
			print "<br/>@$last[0]<br />";
			print "</td>";
			if ($cl >= 4) {	print "</tr>\n"; $cl=0; }else{ $cl++; }
			}
		print "</table>\n";
		print "<center>Empty Statistics table!</center>\n" if (!$no);
		print &endPanel;
	}

if (@err) {
	print &startPanel("Generator :: Warnings & Errors");
	#print "<ul>\n";
	#foreach (@err) { print "<li>$_</li>"; }
	foreach (@err) { print "$_<br>"; }
	#print "</ul>\n";
	print &endPanel;
	}

print &endPage();

exit;
