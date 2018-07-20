#!/usr/bin/perl
# Note: If $separator appears in your variable name, please change it to another
# character
$separator="'";
$file = $ARGV[$#ARGV-1];
$userfile = $ARGV[$#ARGV];
if ($ARGV[$#ARGV] eq "-h" || "$#ARGV" eq "-1") {
	print "\n\nThe command line syntax for running this script is\n\n";
	print "perl blif2book.pl <blif file> <output file>\n\n"; 
	print "Here blif file is the name of your blif file which you want to parse with the .blif extension\n\n";
	print "And the output file is the output base file name\n\n";
	print "For example, if you say\n\n";
	print "perl script abc.blif xyz\n\n";
	print "Then the script would parse abc.blif and generate xyz.nodes, xyz.nets and xyz.aux\n"; 
}
else {
	print "Parsing $file\n";
	print "Please wait...\n";
	open (BLIF1, $file) || die "Cannot open blif: $!";
	open (FINALNODES, ">$userfile.nodes") || die "Cannot find .nodes :$!";
	open (NETS, ">$userfile.nets") || die "Cannot find .nets :$!";
	open (TEMP, ">temp.nets") || die "Cannot find .nets :$!";
	open (NODES, ">temp.nodes") || die "Cannot find .nodes :$!";
	open (NETNODES, ">temp.netnodes") || die "Cannot find .netnodes :$!";
	while (<BLIF1>) {
		if ( /.inputs/ ) {
			$value1 = $_ || die "Cannot find value: $!";
			@valuei = split(/\s+/,$value1);
			foreach $var (@valuei) {
				chomp($var);
				if ($var ne ".inputs" && $var ne "\\" ) {
					$save=$save+1;;
					print NETNODES "$var";	
					$input=$separator . "input";
					$name="$var$input($save)";	
					$terminal = "terminal";
					$r = 1;
					printf NODES "%s \t \t %s %d %d\n", $name, $terminal, $r, $r;
					print NETNODES $separator . "input($save)\n";
					$nodes = $nodes+1;
					$terminals = $terminals+1;
				}
				$some = @valuei[-1];
			}
			if ($some eq "\\") {
				$check = "true";
			}
		}
		while ($check eq "true") {
			$_ = <BLIF1>;
			$value2 = $_ || die "Cannot find value: $!";
			@valuei2 = split(/\s+/,$value2);
			foreach $var2 (@valuei2) {
				chomp($var2);
				if ($var2 ne "\\" ) {
					$save=$save+1;;
					print NETNODES "$var2";
					$name="$var2$input($save)";
					printf NODES "%s \t \t %s %d %d\n", $name, $terminal, $r, $r;  
					print NETNODES $separator . "input($save)\n";
					$nodes = $nodes+1;
					$terminals = $terminals+1;
				}
				$any = @valuei2[-1]; 
			}
			if ($any eq "\\") {
				$check = "true";
			}
			else { 
				$check = "false"; 
			}
		}
		if (/.outputs/) {
			$value2 = $_ || die "Cannot find value: $!";
			@valueo = split(/\s+/,$value2);
			foreach $var (@valueo) {
				chomp($var);
				if ($var ne ".outputs" && $var ne "\\") {
					$save=$save+1;
					$output=$separator . "output";
					$name="$var$output($save)";
					printf NODES "%s \t \t %s %d %d\n", $name, $terminal, $r, $r;
					print NETNODES "$var";	
					print NETNODES $separator . "output($save)\n";
					$nodes=$nodes+1;
					$terminals=$terminals+1;
				}
				$some = @valueo[-1];
			}
			if ($some eq "\\") {
				$check = "true";
			}
		}
		while ($check eq "true") {
			$_ = <BLIF1>;
			$value2 = $_ || die "Cannot find value: $!";
			@valueo2 = split(/\s+/,$value2);
			foreach $var2 (@valueo2) {
				chomp($var2);
				if ($var2 ne "\\" ) {
					$save=$save+1;;
					$ref[$save]=$var2;
					print NETNODES "$var2";
					print NETNODES $separator . "output($save)\n";
					$name="$var2$output($save)";
					printf NODES "%s \t \t %s %d %d\n", $name, $terminal, $r, $r;
					$nodes = $nodes+1;
					$terminals=$terminals+1;
				}
				$any = @valueo2[-1];
			}
			if ($any eq "\\") {
				$check = "true";
			}
			else {
				$check = "false";
			}
		}
		if (/.latch/) {
			$nodes = $nodes+1;        
			$value3 = $_ || die "Cannot find value: $!";
			@valuel = split(/\s+/,$value3);
			foreach $var (@valuel) {
				chomp($var);
				if (($var ne ".latch") && ($var ne "0")) {
					print NODES "$var";
					print NODES $separator;
					$latch="latch";
					print NETNODES "$var";
					print NETNODES $separator;
				}
			}
			$save=$save+1;
			print NODES "latch($save)";
			printf NODES "\t \t  %d %d\n", $r, $r;
			print NETNODES "latch($save)\n";
		}
		if (/.names/ ) {
			$nodes=$nodes+1;
			$value4 = $_ || die "Cannot find value$j: $!";
			@valuen = split(/\s+/,$value4);
			foreach $var (@valuen) {
				chomp($var);
				if ($var ne ".names") {
					print NODES "$var";
					print NODES $separator;
					print NETNODES "$var";
					print NETNODES $separator;
				}
			}
			$save=$save+1;
			$namef="name($save)";
			printf NODES "%s \t \t  %d %d\n", $namef, $r, $r; 
			print NETNODES "name($save)\n";
		}
	}
	close (NETNODES);
	$inputr= $seperator . "input";
	$outputr= $separator . "output";
	$latchr= $separator . "latch";
	$namer= $separator . "name";
	open (NETNODES, "temp.netnodes") || die "Cannot open temp:$!";
	while (<NETNODES>) {
		if (/$inputr/ || /$outputr/ || /$latchr/ || /$namer/) {
			$nodelines = $_ || die "Cannot find $nodelines: $!";
			@data = split(/$separator+/,$nodelines);
			foreach $var (@data) {
				chomp($var);
				$num = $num+1;
				$list[$num]=$var;
			}
		}
	}
	close (NETNODES);
	%hash = ();
	$hash{"key"}="rough";
	for ($i=1;$i<=$num;$i++)
	{
		$netdegree = 0;
		$temp=$list[$i];
		if (! exists($hash{$temp})) {
			$hash{$list[$i]}=$list[$i];
			open (NETNODES, "temp.netnodes");
			$m=0;
			my @lines;
			while (<NETNODES>) {
				$man="$list[$i]".$separator;
				chomp($man);
				if (/\Q$man/) {
					$netdegree=$netdegree+1;
					$pins=$pins+1;
					$m=$m+1;
					$lines[$m] = $_;
				}
			}

			if ("$netdegree" eq "1") {
				$pins=$pins-1;
				print "Warning: Found unconnected nodes in input "; 
				foreach $grey (@lines) {
					print "$grey\n";
				}
			}



			if ($netdegree > 1) {

				$c=$c+1;
				print TEMP "NetDegree   :       $netdegree      S$c\n";
				foreach $grey (@lines) {
					print TEMP "$grey";
				}
			}
		}
		close(NETNODES);
	}
	print NETS "UCLA		nets	1.0\n";
	print NETS "NumPins	:	$pins\n";	
	close (TEMP);
	open (TEMP, "temp.nets") || die "Cannot open temp:$!";
	while (<TEMP>) {
		s/'/_/g;
		print  NETS $_;
	}
	close (NODES);
	print FINALNODES "UCLA	nodes	 1.0\n";
	print FINALNODES "NumNodes :  $nodes\n";
	print FINALNODES "NumTerminals : $terminals\n";
	close (FINALNODES);
	open (FINALNODES, ">>$userfile.nodes") || die "Cannot open .nodes:$!";
	open (NODES, "temp.nodes") || die "Cannot open temp:$!";
	while (<NODES>) {
		s/'/_/g;
		print FINALNODES $_;
	}
	close(NODES);
	close (TEMP);
	close (NETS);
	close (FINALNODES);
	close (BLIF1);
	system("rm -rf temp.nets temp.nodes temp.netnodes"); 

	open (AUX, ">$userfile.aux") || die "Cannot open aux:$!";

	print AUX "RowBasedPlacement : $userfile.nodes $userfile.nets\n";

	close (AUX); 

	print "Parsing Completed for $file\n";
	print "Your output files are $userfile.nodes , $userfile.nets and $userfile.aux\n"; 

}
