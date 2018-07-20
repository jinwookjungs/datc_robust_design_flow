#!/usr/bin/perl

# 02/28/2005 Gi-Joon: modification to reflect un-aligned row configuration 
#                     with RowDBstartX & RowDBendX array
 
# Written by Gi-Joon Nam (gnam@us.ibm.com) on Jan 2005
# usage: legal.pl <nodes> <input.pl> <solution.pl> <scl> <row_num>
#        This perl script checks the following conditions
#        0. whether a terminal obect moved (ERROR Type0)
#        1. whether a movable object is placed outside placement area (ERROR Type1)
#        2. whether a object is aligned to row boundary (ERROR Type2)
#        3. whether there is any overlap among objects (ERROR Type3)
#
# <row_num> defines legality-checking row window sizes (# of rows)
# i.e., window = (image_hx - image_lx) X ROW_JUMP 

$DEFAULT_ROW_HEIGHT = 9; 

%ObjectDB;
@AreaMap;
@RowDB;        # stores row_y_low value for each row.
@RowDBstartX;  # starting X coordinate of each row
@RowDBendX;    # ending X coordinate of each row. RowDBs share the same index
@ErrorDB;

$DXINDEX=0;
$DYINDEX=1;
$LOCXINDEX=2;
$LOCYINDEX=3;
$TYPEINDEX=4;

$n_file = $ARGV[0];
$i_file = $ARGV[1];
$p_file = $ARGV[2];
$s_file = $ARGV[3];
$r_num  = $ARGV[4];

if (!defined($n_file) || !defined($i_file) || !defined($p_file) || !defined($s_file)) {
    print "Usage: check_legalality.pl <NODE file> <PL file> <Solution PL file> <SCL file> <Row_num>\n";
    exit(0);
}

$WINDOW_LX = 100000000;
$WINDOW_LY = 100000000;
$WINDOW_HX = -100000000;
$WINDOW_HY = -100000000;

# ErrorDB setup
for ($errortype = 0; $errortype < 4; $errortype++) {
    $ErrorDB[$errortype] = 0;
}

open (NFILE, $n_file) || die "I can't open node file $n_file\n";
open (IFILE, $i_file) || die "I can't open pl   file $i_file\n";
open (PFILE, $p_file) || die "I can't open sol  file $p_file\n";
open (SFILE, $s_file) || die "I can't open scl  file $s_file\n";
open (EFILE, ">legality.error") || die "I can't open legality.error\n";

###########################
# scl file processing
###########################
$num_processed_rows = 0;
$row_height = $DEFAULT_ROW_HEIGHT; 
while (defined($line = <SFILE>)) {
    $line =~ s/^\s+//; # removes front/end white spaces
    $line =~ s/\s+$//;
    @words = split(/\s+/, $line);

    if ($words[0] eq "#" || $words[0] eq "UCLA") {
	next;
    }
    if ($words[0] eq "NumRows") {
	$num_rows = $words[2];
	print "NumRows: $num_rows are defined\n";
	next;
    }
    if ($words[0] eq "CoreRow") {
	$line = <SFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	# Keyword: Coordinate 
	if ($words[0] eq "Coordinate") {
	    $row_y = $words[2];
	}
	else {
	    print EFILE "ERROR: CoreRow Processing: Coordinate keyword not found\n";
	    print       "ERROR: CoreRow Processing: Coordinate keyword not found\n";
	    my_exit();
	}
	push(@RowDB, $row_y);
	
	# Keyword: Height
	$line = <SFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	$prev_row_height=$row_height;
	if ($words[0] eq "Height") {
	    $row_height = $words[2];
	}
	else {
	    print EFILE "ERROR: CoreRow Processing: Height keyword not found\n";
	    print       "ERROR: CoreRow Processing: Height keyword not found\n";
	    my_exit();
	}

	if ($prev_row_height != $row_height) {
	    print EFILE "ERROR: Row Height mismatch: $prev_row_height vs $row_height\n";
	    print       "ERROR: Row Height mismatch: $prev_row_height vs $row_height\n";
	    my_exit();
	}
	
	# Keyword: Sitewidth
	$line = <SFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] eq "Sitewidth") {
	    $site_width = $words[2];
	}
	else {
	    print EFILE "ERROR: CoreRow Processing: Sitewidth keyword not found\n";
	    print       "ERROR: CoreRow Processing: Sitewidth keyword not found\n";
	    my_exit();
	}
	
	# Keyword: Sitespacing
	$line = <SFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] eq "Sitespacing") {
	    $site_width = $words[2];
	}
	else {
	    print EFILE "ERROR: CoreRow Processing: Sitespacing keyword not found\n";
	    print       "ERROR: CoreRow Processing: Sitespacing keyword not found\n";
	    my_exit();
	}
	
	# Keyword: Siteorient
	$line = <SFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] eq "Siteorient") {
	    $site_orient = $words[2];
	}
	else {
	    print EFILE "ERROR: CoreRow Processing: Siteorient keyword not found. $words[0] $words[1]\n";
	    print       "ERROR: CoreRow Processing: Siteorient keyword not found. $words[0] $words[1]\n";
	    my_exit();
	}
	
	# Keyword: Sitesymmetry
	$line = <SFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] eq "Sitesymmetry") {
	    $site_width = $words[2];
	}
	else {
	    print EFILE "ERROR: CoreRow Processing: Sitesymmetry keyword not found. $words[0] $words[1]\n";
	    print       "ERROR: CoreRow Processing: Sitesymmetry keyword not found. $words[0] $words[1]\n";
	    my_exit();
	}
	
	# Keyword: SubrowOrigin
	$line = <SFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] eq "SubrowOrigin") {
	    $row_x = $words[2];
	    $row_num_sites = $words[5];
	    push(@RowDBstartX, $row_x);
	    push(@RowDBendX, $row_x + $row_num_sites);
	}
	else {
	    print EFILE "ERROR: CoreRow Processing: SubrowOrigin keyword not found\n";
	    print       "ERROR: CoreRow Processing: SubrowOrigin keyword not found\n";
	    my_exit();
	}
	
	# Keyword; End
	$line = <SFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] ne "End") {
	    print EFILE "ERROR: Keyword End is expected. $words[0] shows up\n";
	    print       "ERROR: Keyword End is expected. $words[0] shows up\n";
	    my_exit();
	}
	
	if ($WINDOW_LX > $row_x) {
	    $WINDOW_LX = $row_x;
	}
	if ($WINDOW_HX < $row_x + $row_num_sites) {
	    $WINDOW_HX = $row_x + $row_num_sites;
	}
	if ($WINDOW_LY > $row_y) {
	    $WINDOW_LY = $row_y;
	}
	if ($WINDOW_HY < $row_y + $row_height) {
	    $WINDOW_HY = $row_y + $row_height;
	}
	
	$num_processed_rows++; 
    }
}
close(SFILE);
print "Phase 0: Total $num_processed_rows rows are processed.\n";
print "         ImageWindow=($WINDOW_LX $WINDOW_LY $WINDOW_HX $WINDOW_HY) w/ row_height=$row_height\n";

if (defined($r_num)) {
    $ROW_JUMP = $r_num;
}
else {
    $ROW_JUMP = $num_processed_rows;
}

###################################
# Node file processing
##################################
$num_obj = 0;
$num_terminal = 0;
while (defined($line = <NFILE>)) {
    my @tmpRecord;

    $line =~ s/^\s+//; # removes front/end white spaces
    $line =~ s/\s+$//;
    @words = split(/\s+/, $line);
    @words + 0;
    $num_words = scalar(@words);
    if ($words[0] eq "#" || $words[0] eq "UCLA" || $num_words < 1) {
	# skip comment or UCLA line or empty line
	next;
    }
    if ($words[0] eq "NumNodes") {
	$num_obj_from_file = $words[2];
	$line = <NFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	$num_term_from_file = $words[2];
	print "NumNodes: $num_obj_from_file NumTerminals: $num_term_from_file\n";
	next;
    }
    
    $name = $words[0];
    $dx   = $words[1];
    $dy   = $words[2];
    if ($words[3] eq "terminal") {
	$move_type = "terminal";
	$num_terminal++;
    }
    else {
	$move_type = "movable";
    }
    @tmpRecord = ($dx, $dy, 0, 0, $move_type);
    $ObjectDB{$name} = \@tmpRecord;
    $num_obj++;
}
close(NFILE);
print "Phase 1: Node file processing is done. Total $num_obj objects (terminal $num_terminal)\n";

################################
# Input PL file processing
################################
$num_obj = 0;
$num_terminal = 0;
while (defined($line = <IFILE>)) {
    my @tmpRecord;

    $line =~ s/^\s+//; # removes front/end white spaces
    $line =~ s/\s+$//;
    @words = split(/\s+/, $line);
    @words + 0;
    $num_words = scalar(@words);
    if (($words[0] eq "UCLA") || ($words[0] eq "#") || ($num_words < 1)) {
	# skip comments or UCLA or empty line
	next;
    }

    $name = $words[0];
    $locx = $words[1];
    $locy = $words[2];
  
    if (!defined($ObjectDB{$name})) {
	print EFILE "ERROR: In PL file, undefined object $name appears\n";
	print       "ERROR: In PL file, undefined object $name appears\n";
	my_exit();
    }
    
    $move_type = ${$ObjectDB{$name}}[$TYPEINDEX];
    if ($move_type eq "terminal") {
	$num_terminal++;
	${$ObjectDB{$name}}[$LOCXINDEX] = $locx;
	${$ObjectDB{$name}}[$LOCYINDEX] = $locy;
    }
    else {
	${$ObjectDB{$name}}[$LOCXINDEX] = 0;
	${$ObjectDB{$name}}[$LOCYINDEX] = 0;
    }
    $num_obj++;
}
close(IFILE);
print "Phase 2: Input PL file processing is done.\n";
print "         Total $num_obj objects (terminal $num_terminal)\n";

###################################
# Solution PL file processing
# Also checks ErrorType0: whether a terminal object moved or not
###################################
$num_obj = 0;
$num_terminal = 0;
while (defined($line = <PFILE>)) {
    my @tmpRecord;
    
    $line =~ s/^\s+//; # removes front/end white spaces
    $line =~ s/\s+$//;
    @words = split(/\s+/, $line);
    @words + 0;
    $num_words = scalar(@words);
    if ($words[0] eq "UCLA" || $words[0] eq "#" || $num_words < 1) {
	# skip comment line or UCLA line or empty line
	next;
    }
    
    $name = $words[0];
    $locx = $words[1];
    $locy = $words[2];

    if (!defined($ObjectDB{$name})) {
	print EFILE "ERROR: Undefined object $name appear in PL file.\n";
	print       "ERROR: Undefined object $name appear in PL file.\n";
	my_exit();
    }

    $move_type = ${$ObjectDB{$name}}[$TYPEINDEX];
    if ($move_type eq "terminal") {
	$num_terminal++;
	$stored_locx = ${$ObjectDB{$name}}[$LOCXINDEX];
	$stored_locy = ${$ObjectDB{$name}}[$LOCYINDEX];
	if ($stored_locx != $locx || $stored_locy != $locy) {
	    print EFILE "ERROR Type0 terminal moved: $name from ($stored_locx, $stored_locy) to ($locx, $locy)\n";
	    $ErrorDB[0] += 1;
	}
    }
    
    ${$ObjectDB{$name}}[$LOCXINDEX] = $locx;
    ${$ObjectDB{$name}}[$LOCYINDEX] = $locy;
    
    $num_obj++;
}
close(PFILE);
print "Phase 3: Solution PL file processing is done.\n";
print "         Total $num_obj objects (terminal $num_terminal)\n";

#################################################################################
# ErrorType1 Checking: whether a movable object is placed outside placement area
#################################################################################
$num_obj = 0;
$num_boundary_errors = 0;
foreach $key (keys (%ObjectDB)) {
    $lx = ${$ObjectDB{$key}}[$LOCXINDEX];
    $ly = ${$ObjectDB{$key}}[$LOCYINDEX];
    $dx = ${$ObjectDB{$key}}[$DXINDEX];
    $dy = ${$ObjectDB{$key}}[$DYINDEX];
    $move_type = ${$ObjectDB{$key}}[$TYPEINDEX];
    
    $hx = $lx + $dx - 1;
    $hy = $ly + $dy - 1;
    if ($lx > $WINDOW_HX || $hx < $WINDOW_LX ||
	$ly > $WINDOW_HY || $hy < $WINDOW_LY) {
	if ($move_type eq "terminal") {
	    print EFILE "Perimeter IO: $key($move_type) is at ($lx $ly $hx $hy)\n";
	}
	else {
	    print EFILE "ERROR Type1: $key($move_type) is placed outside placement image area ($lx $ly $hx $hy)\n";
	    $ErrorDB[1] += 1;
	}
    }

    if ($move_type ne "terminal") {
	# Row start x to end x checking
	$hy = $ly + $dy;
	$row_id_l = ($ly - $RowDB[0]) / $row_height;
	$int_row_id = int (($ly - $RowDB[0]) / $row_height);	
	if ($row_id_l != $int_row_id) {
	    print EFILE "ERROR Type2: $key (movable) NOT aligned to row boundary dy=$dy row_id=$row_id_l\n";
	    #$ErrorDB[2] += 1;
	    #my_exit(0);
	}

	$row_id_h = ($hy - $RowDB[0]) / $row_height;
	$int_row_id = int (($hy - $RowDB[0]) / $row_height);
	if ($row_id_h != $int_row_id) {
	    print EFILE "ERROR Type2: $key (movable) NOT aligned to row boundary dy=$dy row_id=$row_id_h\n";
	    #$ErrorDB[2] += 1;
	    #my_exit(0);
	}
	for ($this_row = $row_id_l; $this_row < $row_id_h; $this_row++) {
	    $startX = $RowDBstartX[$this_row];
	    $endX   = $RowDBendX[$this_row];
	    if ($lx < $startX || $hx > $endX) {
		print EFILE "ERROR Type1: $key($move_type) is placed outside row-boundary ($lx $ly $hx $hy)\n";
		print EFILE "           : row $this_row ($startX $endX)\n";
		$ErrorDB[1] += 1;
	    }
	}
    }
    $num_obj++;
}
print "Phase 3: Type1 Checking is done with $ErrorDB[1] errors.\n";
print "         Total $num_obj objects have been visited\n";

##########################################################################
# ErrorType2 & 3 Checking: 
# 1) whether an object is aligned to row boundary (Type2)
# 2) whether there is any overlap among objects   (Type3)
# checking windows is ($WINDOW_HX - $WINDOW_LX) x $ROW_JUMP rows at a time
###########################################################################
for ($map_row_start = 0; $map_row_start < $num_rows; $map_row_start += $ROW_JUMP) {
    $map_row_end = $map_row_start + $ROW_JUMP - 1;
    if ($map_row_end > $num_rows - 1) {
	$map_row_end = $num_rows - 1;
    }
    print "Map Drawing: row id: from $map_row_start to $map_row_end...\n";
    for ($c_row = 0; $c_row < $ROW_JUMP; $c_row++) {
	for ($x = $WINDOW_LX; $x <= $WINDOW_HX; $x++) {
	    @{$AreaMap[$x][$c_row]} = (); # flush array
	}
    }
    
    $num_obj = 0;
    foreach $key (keys (%ObjectDB)) {
	$lx = ${$ObjectDB{$key}}[$LOCXINDEX];
	$ly = ${$ObjectDB{$key}}[$LOCYINDEX];
	$dx = ${$ObjectDB{$key}}[$DXINDEX];
	$dy = ${$ObjectDB{$key}}[$DYINDEX];
	$move_type = ${$ObjectDB{$key}}[$TYPEINDEX];
	
	$hx = $lx + $dx - 1;
	$hy = $ly + $dy;     # wrong version: $hy = $ly + $dy - 1;
	
	if ($lx > $WINDOW_HX || $hx < $WINDOW_LX ||
	    $ly > $WINDOW_HY || $hy < $WINDOW_LY) {
	    next;
	}
	
	$yfactor = $dy / $row_height;
	$row_id_l = ($ly - $RowDB[0]) / $row_height;
	$row_id_h = ($hy - $RowDB[0]) / $row_height;

	$int_row_id = int (($ly - $RowDB[0]) / $row_height);	
	if ($row_id_l != $int_row_id) {
	    print EFILE "ERROR Type2: $key NOT aligned to row boundary dy=$dy row_id=$row_id_l\n";
	    $ErrorDB[2] += 1;
	    #my_exit(0);
	}
	$int_row_id = int (($hy - $RowDB[0]) / $row_height);	
	if ($row_id_h != $int_row_id) {
	    print EFILE "ERROR Type2: $key NOT aligned to row boundary dy=$dy row_id=$row_id_h\n";
	    $ErrorDB[2] += 1;
	    #my_exit(0);
	}
	$row_id_h -= 1; # Similar to $hx = $lx + $dy - 1;

	$this_map_start = 0;
	$this_map_end   = $ROW_JUMP - 1;
	$row_id_l = $row_id_l - $map_row_start;
	if ($row_id_l > 0) {
	    $this_row_start = $row_id_l;
	}
	$row_id_h = $row_id_h - $map_row_start;
	if ($row_id_h < $ROW_JUMP) {
	    $this_row_end = $row_id_h;
	}
	
	for ($this_row = $this_row_start; $this_row <= $this_row_end; $this_row++) {
	    for $x ($lx..$hx) {
		if (($x >= $WINDOW_LX) && ($x <= $WINDOW_HX)) {
		    my @tmpArray;
		    
		    push (@{$AreaMap[$x][$this_row]}, \$key);
		    @tmpArray = @{$AreaMap[$x][$this_row]};
		    @tmpArray + 0;
		    $array_size = scalar(@tmpArray);
		    
		    if ($array_size > 1) {
			$ErrorDB[3] += 1;
			@obj_name = @{$AreaMap[$x][$this_row]};
			$this_row_ly = $RowDB[$this_row];

			print EFILE "ERROR Type3: overlap $x $this_row_ly ($array_size)\n";
			for ($i = 0; $i < $array_size; $i++) {
			    $name = ${@obj_name[$i]};
			    $name_length = length $name;
			    if ($name_length > 0) {
				print EFILE "$name ";
				print       "$name ";
			    }
			    else {
				print EFILE "NULL ";
				print       "NULL ";
			    }
			} 
			print EFILE "\n";
			print       "\n";
			#my_exit();
		    } #if
		}
		else {
		    print EFILE "Unexpected object $key coordiantes ($lx,$ly,$hx,$hy).\n";
		    my_exit();
		}
	    }
	}
	$num_obj++;
    }
}
print "Phase 5: Map Drawing is done.\n";
print "         Total $num_obj objects.\n";
close(EFILE);

print "\nERROR SUMMARY.....\n";
print "Type\tOccurrences\n";
for ($errortype=0; $errortype < 4; $errortype++) {
    $val = $ErrorDB[$errortype];
    print "$errortype\t$val\n"
}

sub my_exit {
  print "Abnormal condition happened. Exit\n";
  exit(1);
}
