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
#
# Imageagent
#

sub genImg {
	# Title, Image Size, Base Image, Images List
	my ($file, $w, $h, $ext, $base, @ilist)=@_;
	return "IMGAgent::Error::[$file, $w, $h, $base, (@ilist)]" if (!$base || !@ilist);
	my $back = Image::Magick->new;
	my $over = Image::Magick->new;
	my $i,$x,$y,$eff,$usedeff,$err,@errlist;
	#print "<hr>DBG::Input:: $file, $w, $h, $base, [@ilist]<hr>";

	#my @efflist = ("Over", "In", "Out", "Atop", "Xor", "Plus", "Minus", "Add", 
	#		"Subtract", "Difference", "Multiply", "Bumpmap", "Copy", 
	#		"CopyRed", "CopyCyan", "CopyGreen", "CopyYellow", "CopyBlue", 
	#		"CopyMagenta", "CopyOpacity", "CopyBlack", "Dissolve", "Clear", 
	#		"Displace", "Modulate", "Threshold"
	#		);
	
	my @efflist = ("Plus", "Minus", "Add", "Subtract", "Difference", "Multiply", 
			"Bumpmap", "CopyRed", "CopyBlue", "CopyGreen", "Displace", 
			"Modulate", "Threshold");

	$err = $over->Read(@ilist);

	push(@errlist,$err) if ($err);

	$err = $back->Read($base);
	push(@errlist,$err) if ($err);
	$err = $back->Resize(geometry=> $w.'x'.$h);
	push(@errlist,$err) if ($err);
	

	foreach (@$over) {
		$x=int(rand($w)+1 - ($w/2));
		$y=int(rand($h)+1 - ($h/2));
		$err = $_->Resize(geometry => $w.'x'.$h);
		push(@errlist,$err) if ($err);
		$eff=$efflist[int(rand(@efflist))];
		#$usedeff .= ", " if ($usedeff);
		#$usedeff .= $eff;
		$err = $back->Composite(image=>$_, compose=>$eff, geometry=>'+'.$x.'+'.$y);
		push(@errlist,$err) if ($err);
		}
#
# Annotate does not work well with Older Image Magic (web.iap.de)
#
#	$err = $back->Annotate(
#			geometry=>'+11+11', 
#			family=>'Clear',
#			style=>'Normal',
#			pointsize=>12, 
#			#fill=>'white', 
#			fill=>'lightgray', 
#			antialias => true, 
#			#stretch=> 'ExtraExpanded',
#			undercolor=>'black', 
#			text=>' .:: nag :: '. $file .' ::.'
#			);
#	push(@errlist,$err) if ($err);


    $err = $back->Write("./gen/" . $file .".". $ext);
	push(@errlist,$err) if ($err);
	undef $back;
	undef $over;
	return @errlist;
	}

sub makeThumb {
	my ($w, $file)=@_;
	return "IMGAgent::Input Error::[$w $file]" if (!$w || !$file);
	my @errlist;
	my $thumb = Image::Magick->new;
	my $err = $thumb->Read("./gen/". $file);
	push(@errlist,$err) if ($err);
	$err = $thumb->Resize(geometry=> $w.'x'.$w);
	push(@errlist,$err) if ($err);
	$err = $thumb->Write("./thumb/". $file);
	push(@errlist,$err) if ($err);
	return @errlist;
	}

sub randImgList {
	# no, list
	my ($no, @list)=@_;
	$no=@list if ($no > @list);
	my @newlist=();
	my $i, $ii, $ri, $found;
	for ($i=0;$i<$no;$i++) {
		$ri=$list[int(rand(@list))];
		$found=0;
		for($ii=0;$ii<@newlist;$ii++) {
			$found=1 if ($newlist[$ii] eq $ri);
			}
		if ($found || !$ri || $ri =~ m/\%/) {
			$i--;
			}else{
			push(@newlist, $ri);
			}
		}
	return @newlist;
	}

sub getDirInfo {
	my $d=shift;
	return if !$d;
	
	opendir(DIR, "$d") || die "I Can't Opendir [$d] : $!\n";
	my @list=readdir(DIR);
	closedir(DIR);

	my $s=0;
	my @nlist;
	foreach (@list) {
		if ($_ !~ m/^\.{1,2}/) {
			$s += (stat($d ."/$_"))[7];
			push(@nlist, $_);
			}
		}
	return ($s, @nlist);
	}

1;