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
# Display Module 
#

sub startPage {
#	my $title=($_[0])? "NAG :: $_[0]" : "NAG :: Net.Art Generator";
	my $title=($_[0])? "net.art generator : nag_05 :: $_[0]" : "NAG :: Net.Art Generator";
	my $lang=($_[1])? $_[1] : "en_US";
	return "
<!DOCTYPE html>
<html>
<head><title>$title</title>
<link rel='stylesheet' type='text/css' href='./nag.css' />
<meta charset='UTF-8'>
</head><body><center>\n"; 
	}

sub endPage {
	return "</center>\n<br /><br /></body>\n</html>\n\n";
	}

sub inputForm {
	my ($name,$query,$w,$ext,$comp)=@_;
	my @wid=(400,600,800);
	my @im=(2,4,6,8);
	my %ext=('jpg'=>'JPEG :: Jpeg Image', 'png'=>'PNG :: Portable Network Graphics Image'); #animated gif is not supported.
	my $out = "<form method='GET'><input type='hidden' name='ac' value='create' /><table>
<tr><td width='30%'><b>Artist</b></td><td width='60%'><b>Title</b></td><td width='10%'><b>Compose</b></td></tr>
<tr><td><input type='text' name='name' value='$name' class='max' /></td>
	<td><input type='text' name='query' value='$query' class='max' /></td>
	<td><select name='comp'>\n";
	foreach (sort @im) { 
		$out .= "<option value='$_'";
		$out .= " SELECTED" if ($_ == $comp);
		$out .= ">$_ Images</option>\n"; 
		}
	
	$out .= "</select></td></tr><tr><td><b>Max Width</b></td><td><b>Extension</b></td><td>&nbsp;</td></tr>
<tr><td><select name='width'>\n";

	foreach (@wid) { 
		$out .= "<option value='$_'";
		$out .= " SELECTED" if ($_ == $w);
		$out .= ">$_ px</option>\n"; 
		}

	$out .="</select></td><td><select name='ext'>\n";
	foreach (sort keys(%ext)) { 
		$out .= "<option value='$_'";
		$out .= " SELECTED" if ($_ eq $ext);
		$out .= ">$ext{$_}</option>\n"; 
		}
	
	$out .="</select></td><td><input type='submit' value='Create' /></td></tr></table></form>\n";
	return $out;
	}

sub startPanel {
	my ($title,$color)=@_;
	$color="#dddddd" if (!$color);
	return "<table width='94%' class='panel'>\n<tr bgcolor='$color'><td>$title</td></tr>\n<tr><td>\n";
	}

sub endPanel {
	return "</td></tr></table>\n";
	}

sub secCheck {
	my $val=shift;
	my @list=@_;
	my $ok=0;
	return $val if (!@list);
	foreach (@list) {
		$ok=1 if $val eq $_;
		}
	return $val if $ok;
	return $list[0];
	}
sub rowTabs {
	my $out="";
	for (my $i=3;$i<@_;$i+=2) {
	   	$out .= "<td bgcolor='$_[0]' nowrap='nowrap' >&nbsp;";
		if ($_[$i] && $_[$i+1]) { $out .= "<a \nhref=\"" . $_[$i+1] . "\">"; }
		if ($_[1] && $_[$i]) { $out .= "<font color='$_[1]'>"; }
		if ($_[$i]) { $out .= "<b>$_[$i]</b>"; }
		if ($_[1] && $_[$i]) { $out .= "</font>"; }
		if ($_[$i] && $_[$i+1]) { $out .= "</a>"; }
		$out .= "&nbsp;</td>";
		#if ($_[$i+2]) {	$out .= "|";  }
		}
	if ($_[2] eq "left") {
		$out = "$out<td width='99%'>&nbsp;</td>";
		}
	elsif ($_[2] eq "right") {
		$out = "<td width='99%'>&nbsp;</td>$out";
		}
	elsif ($_[2] eq "center") {
		$out = "<td width='49%'>&nbsp;</td>$out<td width='49%'>&nbsp;</td>";
		}
	$out = "<table width='100%' cellpadding='4' cellspacing='2' border='0'>\n<tr>$out</tr></table>\n";
	return $out;
	} 

1;

