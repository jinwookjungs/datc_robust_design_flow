#!/usr/bin/perl

# To get your code to print out after each print statement
local $| = 1;

# Written by Gi-Joon Nam (gnam@us.ibm.com) on Feb 2007
# Modified by Jinwook Jung (jinwookjung@kaist.ac.kr) on July 2016
# usage: gen_routing_benchmark.pl <nodes> <solution.pl> <net> <scl> <outputfile> <tile_size> <adjustment_factor%> <safe_guard_factor%> <mode=[2|3]> <num_layers>
$DEFAULT_TILE_SIZE = $ARGV[5];
$DEFAULT_ROW_HEIGHT = 9; 
$DEFAULT_PIN_METAL_LAYTER = 1;
$DEFAULT_WIRE_MINIMUM_WIDTH = 1;
$FANOUT_CLIP_THRESHOLD = 1000;
#$ADJUSTMENT_FACTOR = 0.3; #this is one used for contest benchmark
$ADJUSTMENT_FACTOR = $ARGV[6];
$ADJUSTMENT_FACTOR /= 100.0;
$SAFE_GUARD=$ARGV[7];
$SAFE_GUARD /= 100.0;

%ObjectDB;
%NetDB;
%NetPinDB;
%CapAdjustmentDB;

@RowDB;        # stores row_y_low value for each row.
@RowDBstartX;  # starting X coordinate of each row
@RowDBendX;    # ending X coordinate of each row. RowDBs share the same index

$DXINDEX=0;
$DYINDEX=1;
$LOCXINDEX=2;
$LOCYINDEX=3;
$TYPEINDEX=4;

$nod_file = $ARGV[0];
$sol_file = $ARGV[1];
$net_file = $ARGV[2];
$scl_file = $ARGV[3];
$out_file = $ARGV[4];

$mode = $ARGV[8];
$NUMLAYERS=$ARGV[9];

if (!defined($nod_file) || !defined($sol_file) || !defined($net_file) || !defined($scl_file) || !defined($out_file) ||
    !defined($DEFAULT_TILE_SIZE) || !defined($ADJUSTMENT_FACTOR) || !defined($SAFE_GUARD) || !defined($mode) || !defined($NUMLAYERS)) {
    print "Usage: usage: gen_routing_benchmark.pl <nodes> <solution.pl> <net> <scl> <outputfile> <tile_size> <adjustment_factor%> <safe_guard_factor%> <mode=[2|3]> <num_layers (>=2)>\n";
    exit(0);
}
if ($NUMLAYERS < 2) {
    print "Error: num_layers should be larger than 2.";
    exit(0);
}

if (!defined($out_file)) {
    $out_file = "routing.in";
}

$WINDOW_LX = 100000000;
$WINDOW_LY = 100000000;
$WINDOW_HX = -100000000;
$WINDOW_HY = -100000000;

open (NODFILE, $nod_file) || die "I can't open node   file $nod_file\n";
open (SOLFILE, $sol_file) || die "I can't open sol-pl file $sol_file\n";
open (NETFILE, $net_file) || die "I can't open net    file $net_file\n";
open (SCLFILE, $scl_file) || die "I can't open scl    file $scl_file\n";
open (OUTFILE, ">$out_file") || die "I can't open $out_file\n";

sub my_exit {
  print "Abnormal condition happened. Exit\n";
  exit(1);
}

###########################
# scl file processing
###########################
$num_processed_rows = 0;
$row_height = $DEFAULT_ROW_HEIGHT; 
while (defined($line = <SCLFILE>)) {
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
	$line = <SCLFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	# Keyword: Coordinate 
	if ($words[0] eq "Coordinate") {
	    $row_y = $words[2];
	}
	else {
	    print       "ERROR: CoreRow Processing: Coordinate keyword not found\n";
	    my_exit();
	}
	push(@RowDB, $row_y);
	
	# Keyword: Height
	$line = <SCLFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	$prev_row_height=$row_height;
	if ($words[0] eq "Height") {
	    $row_height = $words[2];
	}
	else {
	    print       "ERROR: CoreRow Processing: Height keyword not found\n";
	    my_exit();
	}

	if ($prev_row_height != $row_height) {
	    print       "ERROR: Row Height mismatch: $prev_row_height vs $row_height\n";
	    my_exit();
	}
	
	# Keyword: Sitewidth
	$line = <SCLFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] eq "Sitewidth") {
	    $site_width = $words[2];
	}
	else {
	    print       "ERROR: CoreRow Processing: Sitewidth keyword not found\n";
	    my_exit();
	}
	
	# Keyword: Sitespacing
	$line = <SCLFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] eq "Sitespacing") {
	    $site_width = $words[2];
	}
	else {
	    print       "ERROR: CoreRow Processing: Sitespacing keyword not found\n";
	    my_exit();
	}
	
	# Keyword: Siteorient
	$line = <SCLFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] eq "Siteorient") {
	    $site_orient = $words[2];
	}
	else {
	    print       "ERROR: CoreRow Processing: Siteorient keyword not found. $words[0] $words[1]\n";
	    my_exit();
	}
	
	# Keyword: Sitesymmetry
	$line = <SCLFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] eq "Sitesymmetry") {
	    $site_width = $words[2];
	}
	else {
	    print       "ERROR: CoreRow Processing: Sitesymmetry keyword not found. $words[0] $words[1]\n";
	    my_exit();
	}
	
	# Keyword: SubrowOrigin
	$line = <SCLFILE>;
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
	    print       "ERROR: CoreRow Processing: SubrowOrigin keyword not found\n";
	    my_exit();
	}
	
	# Keyword; End
	$line = <SCLFILE>;
	$line =~ s/^\s+//; # removes front/end white spaces
	$line =~ s/\s+$//;
	@words = split(/\s+/, $line);
	
	if ($words[0] ne "End") {
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
close(SCLFILE);
print "Phase 0: Total $num_processed_rows rows are processed.\n";
print "         ImageWindow=($WINDOW_LX $WINDOW_LY $WINDOW_HX $WINDOW_HY) w/ row_height=$row_height\n";

###################################
# Node file processing
##################################
$num_obj = 0;
$num_terminal = 0;
$num_large_macro = 0;
while (defined($line = <NODFILE>)) {
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
	$line = <NODFILE>;
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
close(NODFILE);
print "Phase 1: Node file processing is done. Total $num_obj objects (terminal $num_terminal)\n";

###################################
# Solution PL file processing
# Also checks ErrorType0: whether a terminal object moved or not
###################################
$num_obj = 0;
$num_terminal = 0;
$num_large_macro = 0;
while (defined($line = <SOLFILE>)) {
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
	print       "ERROR: Undefined object $name appear in PL file.\n";
	my_exit();
    }

    ${$ObjectDB{$name}}[$LOCXINDEX] = $locx;
    ${$ObjectDB{$name}}[$LOCYINDEX] = $locy;
    $num_obj++;

    $obj_dx = ${$ObjectDB{$name}}[$DXINDEX];
    $obj_dy = ${$ObjectDB{$name}}[$DYINDEX];

    # Large *INTERNAL* macros
    if (is_large_macro($obj_dx, $obj_dy) && ($locx >= $WINDOW_LX) && ($locy >= $WINDOW_LY) && 
	($locx + $obj_dx <= $WINDOW_HX) && ($locy + $obj_dy <= $WINDOW_HY)) {
	$num_large_macro++;
    }
}
close(SOLFILE);
print "Phase 2: Solution PL file processing is done.\n";
print "         Total $num_obj objects. $num_large_macro Large macros\n";

########################
# NET file processing
########################
$num_net = 0;
$num_pin = 0;
$index_net = 0;
$total_wl = 0;
$max_degree = 0;
$num_fanout_clipped = 0;
$num_less_than_two_pin_net = 0;

$minx = 1000000;
$miny = 1000000;
$maxx = -1;
$maxy = -1;
while (defined($line = <NETFILE>)) {
  my @tmpPinArray;
  my @tmpRecord;

  $line =~ s/^\s+//; # removes front/end white spaces
  $line =~ s/\s+$//;
  @words = split(/\s+/, $line);
  @words + 0;
  $num_words = scalar(@words);

  if ($words[0] eq "#" || $words[0] eq "UCLA" || $num_words < 1) {
      next;
  }

  if ($words[0] eq "NumNets") {
      $num_net_from_file = $words[2];
      next;
  }
  if ($words[0] eq "NumPins") {
      $num_pin_from_file = $words[2];
      print "NumNets: $num_net_from_file NumPins: $num_pin_from_file\n";
      next;
  }
  if ($words[0] ne "NetDegree") {
      print "\tError: Expected Keyword NetDegree does not show up. Instead $words[0]\n";
      my_exit();
  }

  $this_num_pin  = $words[2];
  $this_net_name = $words[3];

  #if (defined($NetDB{$this_net_name})) {
  #    $index_net = $NetDB{$this_net_name};
  #    print "\tERROR: Net $this_net_name is defined before (index $index_net)\n";
  #    my_exit();
  #}

  $this_net_wl = 0;
  $this_net_lx = 100000000;
  $this_net_ly = 100000000;
  $this_net_hx = -1;
  $this_net_hy = -1;

  if ($this_num_pin < 2) {
      $num_less_than_two_pin_net++;
  }

  for ($i = 0; $i < $this_num_pin; $i++) {
      my @tmpPinRecord;

      $line = <NETFILE>;
      $line =~ s/^\s+//; # removes front/end white spaces
      $line =~ s/\s+$//;
      @words = split(/\s+/, $line);

      $obj_name = $words[0];
      $in_out   = $words[1];
      $x_offset = $words[3];
      $y_offset = $words[4];

      if (!defined($ObjectDB{$obj_name})) {
	  print "\tERROR: Object $obj_name is NOT defined in ObjectDB.\n";
	  my_exit();
      }
      $obj_lx = ${$ObjectDB{$obj_name}}[$LOCXINDEX];
      $obj_ly = ${$ObjectDB{$obj_name}}[$LOCYINDEX];
      $obj_dx = ${$ObjectDB{$obj_name}}[$DXINDEX];
      $obj_dy = ${$ObjectDB{$obj_name}}[$DYINDEX];

      $obj_cx = $obj_lx + ($obj_dx/2);
      $obj_cy = $obj_ly + ($obj_dy/2);

      $obj_x = $obj_cx + $x_offset;
      $obj_y = $obj_cy + $y_offset;

      if ($minx > $obj_x) {
	  $minx = $obj_x;
      }
      if ($miny > $obj_y) {
	  $miny = $obj_y;
      }
      if ($maxx < $obj_x) {
	  $maxx = $obj_x;
      }
      if ($maxy < $obj_y) {
	  $maxy = $obj_y;
      }

      if ($obj_x < $this_net_lx) {
	  $this_net_lx = $obj_x;
      }
      if ($obj_y < $this_net_ly) {
	  $this_net_ly = $obj_y;
      }
      if ($obj_x > $this_net_hx) {
	  $this_net_hx = $obj_x;
      }
      if ($obj_y > $this_net_hy) {
	  $this_net_hy = $obj_y;
      }
      $num_pin++;
      @tmpPinRecord = ($obj_x, $obj_y, $DEFAULT_PIN_METAL_LAYTER, $obj_lx, $obj_ly, $obj_dx, $obj_dy, $x_offset, $y_offset);
      push(@tmpPinArray, \@tmpPinRecord);
  }

  @tmpRecord = ($index_net, $this_num_pin);
  $NetDB{$this_net_name} = \@tmpRecord;
  $index_net++;
  if ($this_num_pin > $max_degree) {
      $max_degree = $this_num_pin;
  }

  if ($this_num_pin > $FANOUT_CLIP_THRESHOLD) {
      $num_fanout_clipped++;
  }

  $NetPinDB{$this_net_name} = \@tmpPinArray;
  $this_net_wl = (($this_net_hx - $this_net_lx) + ($this_net_hy - $this_net_ly));
  if ($this_net_wl < 0) {
      print "\tERROR: Net $this_net_name HPWL=$this_net_wl (negative wl)\n";
      my_exit();
  }
  $total_wl += $this_net_wl;
  $num_net++;
  #print "this_net: $this_net_wl\ttotal: $total_wl\n";
}
$fanout_clipped_percent = ($num_fanout_clipped / $num_net)*100;

close(NETFILE);
printf("Phase 3: Net file processing is done.\n");
printf("         Total %d nets %d pins. Max degree: %d FanoutClipped: %d ( %.2f %)\n", $num_net, $num_pin, $max_degree, $num_fanout_clipped, $fanout_clipped_percent);
printf("         Total HPWL: $total_wl Less-than-two-pin-net: %d\n", $num_less_than_two_pin_net);

#######################################################################################
# Global Routing Benchmark Generation
#######################################################################################
print "Phase 4: Generating a benchmark\n";
$tile_width  = $DEFAULT_TILE_SIZE;
$tile_height = $DEFAULT_TILE_SIZE;
print "Placement Pin Area: ($minx, $miny) - ($maxx, $maxy)\n";
if ($WINDOW_LX < $minx) {
    $minx = $WINDOW_LX;
}
if ($WINDOW_LY < $miny) {
    $miny = $WINDOW_LY;
}
if ($WINDOW_HX > $maxx) {
    $maxx = $WINDOW_HX;
}
if ($WINDOW_HY > $maxy) {
    $maxy = $WINDOW_HY;
}

# Adjust minx, maxx, miny, maxy so that every pin is covered by bin tiles. 
$minx = $minx - int($tile_width/2.0);
$maxx = $maxx + int($tile_width/2.0);
$miny = $miny - int($tile_height/2.0);
$maxy = $maxy + int($tile_height/2.0);
if ($minx < 0) {
    $minx = 0;
}
if ($miny < 0) {
    $miny = 0;
}
print "Adjusted Area:      ($minx, $miny) - ($maxx, $maxy)\n";

#Routing benchmark Analysis
@PinTileIndexList;
@TotalNetLengthPerPinDB;
@NumNetPerPinDB;

# 1. Header
$total_capacity = 0;
if ($mode == 3) {
    # $numlayer = 6;
    $numlayer = $NUMLAYERS;
}
else {
    $numlayer = 2;
}
#$image_dx = $WINDOW_HX - $WINDOW_LX;
#$image_dy = $WINDOW_HY - $WINDOW_LY;
$image_dx = $maxx - $minx;
$image_dy = $maxy - $miny;

$xgrid = int(($image_dx / $tile_width ) + 0.5);
$ygrid = int(($image_dy / $tile_height) + 0.5);

# make metal tracks even
#$m1_capacity = int($tile_height * 0.2 * $SAFE_GUARD);
#$m2_capacity = int($tile_width  * 0.2 * $SAFE_GUARD);
$m1_capacity = int($tile_height * $ADJUSTMENT_FACTOR * $SAFE_GUARD);
$m2_capacity = int($tile_width  * $ADJUSTMENT_FACTOR * $SAFE_GUARD);

if (is_odd($m1_capacity)) {
    $m1_capacity += 1;
}
if (is_odd($m2_capacity)) {
    $m2_capacity += 1;
}

$base_hori_capacity = int($tile_height * $SAFE_GUARD);
$base_vert_capacity = int($tile_width  * $SAFE_GUARD);

if (is_odd($base_hori_capacity)) {
    $base_hori_capacity += 1;
}
if (is_odd($base_vert_capacity)) {
    $base_vert_capacity += 1;
}

if ($mode == 3) {
    print OUTFILE "grid\t$xgrid $ygrid $numlayer\n";
    print OUTFILE "vertical capacity\t0 $m2_capacity ";
    for ($i = 3; $i <= $numlayer; $i++) {
        if (is_odd($i)) {
            print OUTFILE "0 ";
        }
        else {
            print OUTFILE "$base_vert_capacity ";
        }
    }
    print OUTFILE "\n";
    print OUTFILE "horizontal capacity\t$m1_capacity 0 ";
    for ($i = 3; $i <= $numlayer; $i++) {
        if (is_odd($i)) {
            print OUTFILE "$base_hori_capacity ";
        }
        else {
            print OUTFILE "0 ";
        }
    }
    print OUTFILE "\n";
    print OUTFILE "minimum width\t";
    for ($i = 1; $i <= $numlayer; $i++) {
        print OUTFILE "1 ";
    }
    print OUTFILE "\n";
    print OUTFILE "minimum spacing\t";
    for ($i = 1; $i <= $numlayer; $i++) {
        print OUTFILE "1 ";
    }
    print OUTFILE "\n";
    print OUTFILE "via spacing\t";
    for ($i = 1; $i <= $numlayer; $i++) {
        print OUTFILE "1 ";
    }
    print OUTFILE "\n";
    print OUTFILE "$minx $miny $tile_width $tile_height\n\n";
    $total_capacity  = $m1_capacity * ($xgrid - 1) * $ygrid;
    $total_capacity += $m2_capacity * ($ygrid - 1) * $xgrid;
    $total_capacity += ($base_hori_capacity * ($xgrid - 1) * $ygrid) * 2;
    $total_capacity += ($base_vert_capacity * ($ygrid - 1) * $xgrid) * 2;
}
else {
    $d2_hori_base_capacity = $m1_capacity + $base_hori_capacity + $base_hori_capacity;
    $d2_vert_base_capacity = $m2_capacity + $base_vert_capacity + $base_vert_capacity;
    
    if (is_odd($d2_hori_base_capacity)) {
	$d2_hori_base_capacity += 1;
    }
    if (is_odd($d2_vert_base_capacity)) {
	$d2_vert_base_capacity += 1;
    }
    print OUTFILE "grid\t$xgrid $ygrid $numlayer\n";
    print OUTFILE "vertical capacity\t0 $d2_vert_base_capacity\n";
    print OUTFILE "horizontal capacity\t$d2_hori_base_capacity 0\n";
    print OUTFILE "minimum width\t1 1\n";
    print OUTFILE "minimum spacing\t1 1\n";
    print OUTFILE "via spacing\t1 1\n";
    print OUTFILE "$minx $miny $tile_width $tile_height\n\n";
    $total_capacity  = $d2_hori_base_capacity * ($xgrid - 1) * $ygrid;
    $total_capacity += $d2_vert_base_capacity * ($xgrid - 1) * $ygrid;
}

$num_total_tile = $xgrid * $ygrid;
print "\nBenchmark Header: TileWidth $tile_width TileHeight $tile_height $xgrid x $ygrid ($num_total_tile)\n";

$updated_num_net = $num_net - $num_less_than_two_pin_net;
print OUTFILE "num net $updated_num_net\n";
# 2. Net section
$num_single_bin_net = 0;
$debug_num_pin = 0;
$debug_num_net = 0;
$debug_total_num_pin = 0;
$total_tile_hpwl = 0;
$debug_flag = 0;
foreach $net_name (sort(keys (%NetPinDB))) {
    my @tmpPinArray;

    @tmpPinArray = @{$NetPinDB{$net_name}}; 
    $id      = ${NetDB{$net_name}}[0];
    $num_pin = ${NetDB{$net_name}}[1];

    if ($num_pin < 2) {
	#print "ERROR: net $net_name has less than 2 pins: $num_pin\n";
	next;
    }
    @PinTileIndexList = ();
    #if ($num_pin <= $FANOUT_CLIP_THRESHOLD) {
	#print OUTFILE "Net $net_name\n";
    print OUTFILE "$net_name $id $num_pin $DEFAULT_WIRE_MINIMUM_WIDTH\n";

    $debug_num_pin = 0;    
    foreach $one (@tmpPinArray) {
	my @tmpPinRecord;
	
	@tmpPinRecord = @{$one};
	$x = $tmpPinRecord[0];
	$y = $tmpPinRecord[1];
	$l = $tmpPinRecord[2];
	
	$lx = $tmpPinRecord[3]; # obj_lx
	$ly = $tmpPinRecord[4]; # obj_ly
	$dx = $tmpPinRecord[5]; # obj_dx
	$dy = $tmpPinRecord[6]; # obj_dy
	$ox = $tmpPinRecord[7]; # x_offset
	$oy = $tmpPinRecord[8]; # y_offset
	
	#print OUTFILE "\t$x\t$y\t$l\tlx $lx\tly $ly\tdx $dx\tdy $dy\tox $ox\toy $oy\n";
	$old_x = $x;
	$old_y = $y;
	$x = round_up_int($x);
	$y = round_up_int($y);
	if (int($old_x) != $old_x || int($old_y) != $old_y) {
	    $debug_flag = 1;
	}
	print OUTFILE "$x\t$y\t$l\n";
	
	#Analysis Data
	$xindex = int(($x - $minx)/$tile_width);
	$yindex = int(($y - $miny)/$tile_height);
	
	$index_string = "$xindex".":"."$yindex"; # : is used as a delimeter
	push(@PinTileIndexList, $index_string);
	$debug_num_pin++;
	$debug_total_num_pin++;
    }
    $num_list = scalar(@PinTileIndexList);
    if ($num_list != $num_pin) {
	print "ERROR: number of pins does tno match each other: $num_list vs. $num_pin\n";
	my_exit();
    }
    if ($debug_num_pin != $num_pin) {
	print "ERROR: number of pins does tno match each other: Net = $net_name $debug_num_net vs. $num_pin\n";
	my_exit();
    }
    
    $min_x_pin_index = 1000000;
    $min_y_pin_index = 1000000;
    $max_x_pin_index = -1;
    $max_y_pin_index = -1;
    $this_net_manhattan_tile_distance = 0;
    foreach $b (sort(@PinTileIndexList)) {
	@fields = split(/:+/, $b);
	$x_pin_index = $fields[0];
	$y_pin_index = $fields[1];
	#print "$x $y|";
	$min_x_pin_index = my_min($x_pin_index, $min_x_pin_index);
	$min_y_pin_index = my_min($y_pin_index, $min_y_pin_index);
	$max_x_pin_index = my_max($x_pin_index, $max_x_pin_index);
	$max_y_pin_index = my_max($y_pin_index, $max_y_pin_index);
    }
    $this_net_manhattan_tile_distance = ($max_x_pin_index - $min_x_pin_index) + ($max_y_pin_index - $min_y_pin_index);
    if ($this_net_manhattan_tile_distance == 0) {
	$num_single_bin_net++;
    }
    else {
	if (!defined($TotalNetLengthPerPinDB[$num_pin])) {
	    $TotalNetLengthPerPinDB[$num_pin] = $this_net_manhattan_tile_distance;
	    $NumNetPerPinDB[$num_pin] = 1;
	}
	else {
	    $TotalNetLengthPerPinDB[$num_pin] += $this_net_manhattan_tile_distance;
	    $NumNetPerPinDB[$num_pin] += 1;
	}
    }
    #print "\n";
    #}
    
#    print "$num_pin The naive list: ";
#    foreach $b (@PinTileIndexList) {
#	print "$b ";
#    }
#    print "\n";
    
#    print "The sorted list: ";
#    foreach $b (sort(@PinTileIndexList)) {
#	print "$b ";
#    }
#    print "\n";
    $total_tile_hpwl += $this_net_manhattan_tile_distance;
    @PinTileIndexList = ();
    $debug_num_net++;
}
if ($debug_num_net != $updated_num_net) {
    print "ERROR: net number mismatch $debug_num_net vs. $updated_num_net\n";
    my_exit();
}
printf("Total %d nets %d pins\n", $debug_num_net, $debug_total_num_pin);
printf("Single bin nets: %d Total %d nets (%.2f %)\n", $num_single_bin_net, $debug_num_net, ($num_single_bin_net / $debug_num_net)*100);
printf("Global Routing Net Average Length Profile.....\n");
for ($dbindex = 2; $dbindex <= 6; $dbindex++) {
    if ($NumNetPerPinDB[$dbindex] != 0 && defined($NumNetPerPinDB[$dbindex])) {
	$avg_wl = $TotalNetLengthPerPinDB[$dbindex]/$NumNetPerPinDB[$dbindex];
	printf("\t%d\t%.2f\n", $dbindex, $avg_wl);
    }
}
printf("\n");
print OUTFILE "\n";

#print OUTFILE "CAP\n";
# 3. Capacity adjustment section
$num_large_macro = 0;
$num_cap_adjustment_processed = 0;
$num_hori_adjustment = 0;
$num_vert_adjustment = 0;
$num_adjustment_duplication = 0;
foreach $name (keys (%ObjectDB)) {

    $obj_lx = ${$ObjectDB{$name}}[$LOCXINDEX];
    $obj_ly = ${$ObjectDB{$name}}[$LOCYINDEX];
    $obj_dx = ${$ObjectDB{$name}}[$DXINDEX];
    $obj_dy = ${$ObjectDB{$name}}[$DYINDEX];

    if (is_large_macro($obj_dx, $obj_dy) && ($obj_lx >= $WINDOW_LX) && ($obj_ly >= $WINDOW_LY) && 
	($obj_lx + $obj_dx <= $WINDOW_HX) && ($obj_ly + $obj_dy <= $WINDOW_HY)) {

	$num_large_macro++;
	$obj_hx = $obj_lx + $obj_dx;
	$obj_hy = $obj_ly + $obj_dy;

	$x_l_index = int(($obj_lx - $minx)/$tile_width);
	$x_h_index = int(($obj_hx - $minx)/$tile_width);
	$y_l_index = int(($obj_ly - $miny)/$tile_height);
	$y_h_index = int(($obj_hy - $miny)/$tile_height);

	if ($x_l_index < 0 || $x_h_index >= $xgrid || $y_l_index < 0 || $y_h_index >= $ygrid) {
	    print "ERROR: Wrong index during large macro $name processing ($obj_lx, $obj_ly)-->($obj_hx, $obj_hy) Index: ($x_l_index,$y_l_index)-->($x_h_index,$y_h_index)\n";
	    my_exit();
	}

	if ($x_h_index > $x_l_index || $y_h_index > $y_l_index) {
	    for ($iy = $y_l_index; $iy <= $y_h_index; $iy++) {
		for ($ix = $x_l_index; $ix <= $x_h_index - 1; $ix++) {
		    $index_string = "$ix".":"."$iy".":"."R";
		    if (!defined($CapAdjustmentDB{$index_string})) {
			$CapAdjustmentDB{$index_string} = 1;
			$num_hori_adjustment++;
		    }
		    else {
			$CapAdjustmentDB{$index_string} += 1;
			$num_adjustment_duplication++;
		    }
		    # Only metal 1 (horizontal)
		    $num_cap_adjustment_processed++;
		}
	    }
	    for ($ix = $x_l_index; $ix <= $x_h_index; $ix++) {
		for ($iy = $y_l_index; $iy <= $y_h_index - 1; $iy++) {
		    $index_string = "$ix".":"."$iy".":"."U";
		    if (!defined($CapAdjustmentDB{$index_string})) {
			$CapAdjustmentDB{$index_string} = 1;
			$num_vert_adjustment++;
		    }
		    else {
			$CapAdjustmentDB{$index_string} += 1;
			$num_adjustment_duplication++;
		    }
		    # Only metal 2 (vertical)
		    $num_cap_adjustment_processed++;
		}
	    }
	}   
    }
}
print "$num_large_macro Large macro processed. There are $num_cap_adjustment_processed capacity adjustments processed(H: $num_hori_adjustment V: $num_vert_adjustment) Duplication: $num_adjustment_duplication\n";

#print OUTFILE "CAPACITY ADJUSTMENT\n";
$num_cap_adjustment = $num_hori_adjustment + $num_vert_adjustment;
print OUTFILE "\n$num_cap_adjustment\n";
print "CAPACITY ADJUSTMENT: $num_cap_adjustment\n";
$num_cap_adjustment = 0;
$num_hori_adjustment = 0;
$num_vert_adjustment = 0;
$num_warning = 0;
$num_db_entry = 0;
foreach $key_string (keys(%CapAdjustmentDB)) {
    $index_string = $key_string;
    @fields = split(/:+/, $index_string);
    $row = $fields[0];
    $col = $fields[1];
    $direction = $fields[2];
    $val = $CapAdjustmentDB{$key_string};

    if ($val != 1) {
	#print OUTFILE "WARNING: [$row $col $direction] = $val During capacity adjustment, Wrong adjustment value $val encountered\n";
	$num_warning++;
	#my_exit();
    }

    if ($direction eq "R") {
	# each occurrance corresponds to 10% reduction
	$newval = int($base_hori_capacity*(1.0 - $val * $ADJUSTMENT_FACTOR ));
	$adjusted_value = my_max(0, $newval);
	$i = $row + 1;

	if ($mode == 3) {
	    if (is_odd($adjusted_value)) {
		$adjusted_value += 1;
	    }
	    # M3 adjustment
	    print OUTFILE "$row $col 3\t$i $col 3\t$adjusted_value\n";
	    $total_capacity -= ($base_hori_capacity - $adjusted_value);
	}
	else {
	    $total_adjusted_value = $m1_capacity + $adjusted_value + $base_hori_capacity;
	    if (is_odd($total_adjusted_value)) {
		$total_adjusted_value += 1;
	    }
	    print OUTFILE "$row $col 1\t$i $col 1\t$total_adjusted_value\n";
	    $total_capacity -= ($d2_hori_base_capacity - $total_adjusted_value);
	}

	$num_hori_adjustment++;
    }
    elsif ($direction eq "U") {
	$newval = int($base_vert_capacity*(1.0 - $val * $ADJUSTMENT_FACTOR ));
	$adjusted_value = my_max(0, $newval);
	$i = $col + 1;

	if ($mode == 3) {
	    if (is_odd($adjusted_value)) {
		$adjusted_value += 1;
	    }
	    # M4 adjustment
	    print OUTFILE "$row $col 4\t$row $i 4\t$adjusted_value\n";
	    $total_capacity -= ($base_vert_capacity - $adjusted_value);
	}
	else {
	    $total_adjusted_value = $m2_capacity + $adjusted_value + $base_vert_capacity;
	    if (is_odd($total_adjusted_value)) {
		$total_adjusted_value += 1;
	    }
	    print OUTFILE "$row $col 2\t$row $i 2\t$total_adjusted_value\n";
	    $total_capacity -= ($d2_vert_base_capacity - $total_adjusted_value);
	}
	$num_vert_adjustment++;
    }
    else {
	print "ERROR: During capacity adjustment, Wrong direction $direction encountered\n";
	my_exit();
    }
    $num_cap_adjustment++;
    $num_db_entry++;
}
printf("Toatl %d processed and Total %d (%.2f %) edge capacity adjustments\n", $num_large_macro, $num_cap_adjustment, ($num_cap_adjustment / ((($xgrid - 1)* $ygrid) + ($xgrid * ($ygrid - 1)))) * 100);
printf("\t(H: %d V: %d) Warning: %d NumDBEntry: %d\n",  $num_hori_adjustment, $num_vert_adjustment, $num_warning, $num_db_entry);

if ($num_hori_adjustment + $num_vert_adjustment + $num_adjustment_duplication != $num_cap_adjustment_processed) {
    print "ERROR: Cap adjustment failed in matching numbers.\n";
}
$total_capacity /= 2.0; # Due to wire spacing
printf("Total tile HPWL: %d Total Cap: %d Ratio: %.4f %\n", $total_tile_hpwl, $total_capacity, ($total_tile_hpwl / $total_capacity)*100);
if ($debug_flag == 1) {
    print "This benchmark FLAGGED!!!\n";
}
############################################
#Subroutine
############################################
sub my_max {
    $x = $_[0];
    $y = $_[1];
    if ($x > $y) {
	return $x;
    }
    else {
	return $y;
    }
}

sub my_min {
    $x = $_[0];
    $y = $_[1];
    if ($x > $y) {
	return $y;
    }
    else {
	return $x;
    }
}

sub is_odd {
    if ($_[0] % 2 == 0) {
	return 0;
    }
    else {
	return 1;
    }
}

sub is_large_macro {
    $sub_dx = $_[0];
    $sub_dy = $_[1];
    $LARGE_THRESHOLD = $DEFAULT_ROW_HEIGHT * 3;

    if ($sub_dx > $LARGE_THRESHOLD || $sub_dy > $LARGE_THRESHOLD) {
	return 1;
    }
    else {
	return 0;
    }
}

sub round_up_int {
    $arg = $_[0];
    $arg += 0.5;
    
    return int($arg);
}
