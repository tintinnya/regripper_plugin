#-----------------------------------------------------------
# winpkey.pl
#
#
# Change History:
#   20210310 - created
#
# modifying from winver.pl plugin from 2020
# copyright 2020 Quantum Analytics Research, LLC
# Author: H. Carvey, keydet89@yahoo.com
#
# adopting key convertion from https://www.techspot.com/articles-info/1760/images/Win10KeyFinder.txt
# Author: Burman Noviansyah (@tintinnya)
#-----------------------------------------------------------
package winpkey;
use strict;

my %config = (hive          => "Software",
              osmask        => 22,
              hasShortDescr => 1,
              hasDescr      => 0,
              hasRefs       => 0,
              version       => 20210310);

sub getConfig{return %config}

sub getShortDescr {
	return "Get Windows Product Key";	
}
sub getDescr{}
sub getRefs {}
sub getHive {return $config{hive};}
sub getVersion {return $config{version};}

my $VERSION = getVersion();

sub pluginmain {
	my $class = shift;
	my $hive = shift;
	::logMsg("Launching winpkey v.".$VERSION);
	::rptMsg("winpkey v.".$VERSION); 
	::rptMsg("(".getHive().") ".getShortDescr()."\n"); 
  
	my %vals = (1 => "ProductName",
                    2 => "ReleaseID",
	            3 => "ProductID");
         
	my $reg = Parse::Win32Registry->new($hive);
	my $root_key = $reg->get_root_key;
	my $key_path = "Microsoft\\Windows NT\\CurrentVersion";
	my $key;
	if ($key = $root_key->get_subkey($key_path)) {
		
		foreach my $v (sort {$a <=> $b} keys %vals) {
			
			eval {
				my $i = $key->get_value($vals{$v})->get_data();
				::rptMsg(sprintf "%-25s %-20s",$vals{$v},$i);
			};
		}
		
		
	}
	my $key_path = "Microsoft\\Windows NT\\CurrentVersion\\DefaultProductKey";
	if ($key = $root_key->get_subkey($key_path)) {
		my $keyBinary = $key->get_value("DigitalProductId4")->get_data();
		my @keys = unpack 'a' x length $keyBinary, $keyBinary;	
			
		my $keyOffset = 52;

		my $win8 = int($keys[66] / 6);
		my $isWin8 = $win8 & 1;

		$keys[66] = ($keys[66] & (hex 'F7')) | (($isWin8 & 2) * 4); 

		my $i = 24;
		my $maps = "BCDFGHJKMPQRTVWXY2346789";
		my @keymap = unpack 'a' x length $maps, $maps;
		my $keyOutput = "";
		my $last = 0;
		do {
			my $current = 0;
			my $j = 14;
			do {
				$current = $current * 256;
				$current = $keys[$j+ $keyOffset] + $current;
				$keys[$j + $keyOffset] = int($current/24);
				$current = $current % 24;
				$j = $j - 1;
			} while ( $j >= 0 );
			$i = $i - 1;
			$keyOutput = $keyOutput . $keymap[$current + 1];
			$last = $current;
		} while ( $i >= 0 );
		my $strKey = substr($keyOutput, 0,5)."-".substr($keyOutput, 5,5)."-".substr($keyOutput, 10,5)."-".substr($keyOutput, 15,5)."-".substr($keyOutput, 20,5);
		::rptMsg(sprintf "%-25s %-20s","InstalledKey",$strKey);
		if ($isWin8 == 1) {
			my $keypart = substr($keyOutput, 2, $last);

			my $insert = "N";
			$keyOutput =~ s/$keypart/$keypart$insert/ ;
			if ($last == 0) {
				$keyOutput = $insert . $keyOutput
			}
			my $strKey = substr($keyOutput, 0,5)."-".substr($keyOutput, 5,5)."-".substr($keyOutput, 10,5)."-".substr($keyOutput, 15,5)."-".substr($keyOutput, 20,5);
			::rptMsg(sprintf "%-25s %-20s","InstalledKey",$strKey);

		}

	}
	else {
		::rptMsg($key_path." not found.");
	}
}
1;
