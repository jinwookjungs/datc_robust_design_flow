#!/usr/bin/perl

# --------------------------------------------------------------------------------------
# DAC 2012 Routability-driven Placement Contest Evaluation Script
# --------------------------------------------------------------------------------------
# Author:
#   Natarajan Viswanathan, IBM Corp., Austin, TX (nviswan@us.ibm.com)
#   Yaoguang Wei, IBM Corp., Austin, TX (weiyg@us.ibm.com)
# Usage:
#   dac2012_evaluate_solution.pl <circuit.aux> <placement solution> <routing solution>
# --------------------------------------------------------------------------------------
# NOTES:
#   (1) This script borrows functionality to parse a routing solution from the 
#       ISPD 2008 Global Routing Contest evaluation script maintained by:
#         Dr. Cliff Sze, IBM Research, Austin, TX (csze@austin.ibm.com)
#         Dr. Philip Chong, Cadence Research Labs., Berkeley, CA (pchong@cadence.com)
#         Dr. Mehmet C. Yildiz, IBM Corp., Austin, TX (mcan@us.ibm.com)
#   (2) This script assumes that all nodes are placed in their default orientation, 
#       which is N. For the DAC 2012 contest, no flipping / mirroring / rotation 
#       of the nodes is allowed
# --------------------------------------------------------------------------------------

use strict;
use Getopt::Std;
use File::Basename;
use POSIX;

our($opt_h, $opt_p, $opt_v, $opt_c);
getopts('hpcv:');

if(($#ARGV < 2) || ($opt_h))
{
  print "Usage:\n";
  print "   $0 [options] <circuit.aux> <placement solution> <routing solution>\n";
  print "       circuit.aux:        Benchmark auxiliary file\n";
  print "       placement solution: Solution .pl file from the placer\n";
  print "       routing solution:   Solution file from the router\n";
  print "Options:\n";
  print "   -h          Print this help message and exit\n";
  print "   -p          Generate congestion plots for each layer in gnuplot format\n";
  print "   -c          Check the routing solution. Default: OFF\n";
  print "   -v [level]  Verbosity level (0-2). Default: 1\n";
  print "Output:\n";
  print "   HPWL      : Total Half Perimeter Wire Length\n";
  print "   ACE(x)    : Average Congestion of the top x% congested g-edges\n";
  print "               x is an element of {0.5, 1, 2, 5}\n";
  print "   Scaled_WL : Scaled Wire Length = HPWL * Congestion_Penalty\n";
  print "               (DAC 2012 contest evaluation metric excluding runtime)\n";
  exit(0);
}


#### Options ####
my $VERBOSE = 1;
if(defined($opt_v))
{
  $VERBOSE = $opt_v;
}
my $PLOT_CONGESTION = 0;
if($opt_p)
{
  $PLOT_CONGESTION = 1;
}
my $CHECK_WIRES = 0;
if($opt_c)
{
  $CHECK_WIRES = 1;
}


#### Constants ####
my $MAX_VAL = 100000000;
my $MIN_VAL = -100000000;
# Default metal layer for object pins
my $DEF_PIN_METAL_LAYER = 1;
# Indices for object attributes in ObjectDB
my $XLOWINDEX = 0;
my $YLOWINDEX = 1;
my $DXINDEX   = 2;
my $DYINDEX   = 3;
my $TYPEINDEX = 4;
my $PINLAYERINDEX = 5;
my $SHAPEINDEX = 6;
# Via cost for routed wire length calculation
my $VIA_COST = 1;
# For ACE computation
my $IGNORE_EDGE_RATIO = 0.8;
my @ACE_PERCENT_ARRAY = (0.5, 1.0, 2.0, 5.0);
# For Scaled_WL computation
my @CONGESTION_WEIGHT = (1.0, 1.0, 1.0, 1.0);
my $PENALTY_FACTOR    = 0.03;
# Pin blockage factor
my $PIN_BLOCKAGE_FACTOR = 0.0;


############## Main ##############
{
  my $aux_file   = $ARGV[$#ARGV-2];
  my $place_file = $ARGV[$#ARGV-1];
  my $route_file = $ARGV[$#ARGV];
  die "ERROR: .aux file does not exist\n" unless(-e $aux_file);
  die "ERROR: placement solution file does not exist\n" unless(-e $place_file);
  die "ERROR: routing solution file does not exist\n" unless(-e $route_file);
  
  # Handle compressed solution files
  if($place_file =~ /\.gz$/)
  {
    $place_file = "gunzip -c $place_file |";
  }
  elsif($place_file =~ /\.bz2$/)
  {
    $place_file = "bunzip2 -c $place_file |";
  }
  if($route_file =~ /\.gz$/)
  {
    $route_file = "gunzip -c $route_file |";
  }
  elsif($route_file =~ /\.bz2$/)
  {
    $route_file = "bunzip2 -c $route_file |";
  }
  
  my %DesignDB;         # Benchmark file name information
  my %ObjectDB;         # Object information
  my %NetDB;            # Netlist information
  my %RouteDB;          # Routing parameters (not actual routing solution)
  my %TileCapacityDB;   # G-cell(tile) edge capacity information
  my %TileDemandDB;     # G-cell(tile) edge demand (from routing solution)
  my %NetRouteDB;       # Routes for each net
  my %MetricsDB;        # Metrics from placement and routing
  
  # (1) Get benchmark information and placement solution
  read_aux_file($aux_file, \%DesignDB);
  read_nodes_file($DesignDB{nodes}, \%ObjectDB);
  read_shapes_file($DesignDB{shapes}, \%ObjectDB);
  read_pl_file($place_file, \%ObjectDB);
  read_nets_file($DesignDB{nets}, \%ObjectDB, \%NetDB);
  read_route_file($DesignDB{route}, \%ObjectDB, \%RouteDB);
  
  # (2) Get g-cell(tile) edge capacities for each layer
  get_tile_capacity(\%ObjectDB, \%NetDB, \%RouteDB, \%TileCapacityDB);
  
  # (3) Get routing information, including tile demand for each layer
  read_routing_solution($route_file, \%ObjectDB, \%NetDB, \%RouteDB, 
                        \%TileDemandDB, \%NetRouteDB);
  
  # (4) Evaluate the routing solution
  get_congestion_stats(\%RouteDB, \%TileCapacityDB, \%TileDemandDB, \%MetricsDB);
  
  # (5) Evaluate Scaled WL and print metrics
  $MetricsDB{HPWL} = $NetDB{tot_wl};
  print_metrics($aux_file, \%MetricsDB);
  
  # (6) Generate plots if requested
  plot_congestion_maps($aux_file, \%RouteDB, \%TileCapacityDB, \%TileDemandDB) 
  if($PLOT_CONGESTION);
}
##################################


###########################
# .aux file processing
###########################
sub read_aux_file {
  my ($aux_file, $ref_DesignDB) = @_;
  my ($filename, $dir) = fileparse($aux_file);
  
  open(AUXFILE, $aux_file) or die "Can't open: $aux_file ($!)\n";
  
  while(<AUXFILE>) {
    $_ = process_line($_);
    if(/^(RowBasedPlacement)/)
    {
      my @temp = split;
      $ref_DesignDB->{nodes}  = $dir . $temp[2];
      $ref_DesignDB->{nets}   = $dir . $temp[3];
      $ref_DesignDB->{wts}    = $dir . $temp[4];
      $ref_DesignDB->{pl}     = $dir . $temp[5];
      $ref_DesignDB->{scl}    = $dir . $temp[6];
      $ref_DesignDB->{shapes} = $dir . $temp[7];
      $ref_DesignDB->{route}  = $dir . $temp[8];
      last;
    }
    else
    {
      next;
    }
  }
  
  close(AUXFILE);
}

###################################
# .nodes file processing
##################################
sub read_nodes_file {
  my ($nodes_file, $ref_ObjectDB) = @_;
  my ($temp, @temp, $movetype);
  
  print "Phase 1: .nodes file\n" if($VERBOSE);
  
  open(NODESFILE, $nodes_file) or die "Can't open: $nodes_file ($!)\n";
  
  my $num_node_records = 0;
  my $fixed = 0;
  my $nifixed = 0;
  while(<NODESFILE>)
  {
    $_ = process_line($_);
    if(/^(UCLA)/ or /^\s*$/ or /^#.*/)
    {
      next;
    }
    elsif(/^(NumNodes)/)
    {
      ($temp, $ref_ObjectDB->{num_nodes}) = split ":";
      $ref_ObjectDB->{num_nodes} = process_line($ref_ObjectDB->{num_nodes});
    }
    elsif(/^(NumTerminals)/)
    {
      ($temp, $ref_ObjectDB->{num_terminals}) = split ":";
      $ref_ObjectDB->{num_terminals} = process_line($ref_ObjectDB->{num_terminals});
    }
    else
    {
      $num_node_records++;
      @temp = split;
      if($temp[3] =~ /(terminal_NI)/)
      {
        $movetype = "terminal_NI";
        $nifixed++;
      }
      elsif($temp[3] =~ /(terminal)/)
      {
          #$movetype = "terminal";
          #$fixed++;
        $movetype = "terminal_NI";
        $nifixed++;
      }
      else
      {
        $movetype = "movable";
      }
      # (xlow, ylow, width, height, movetype, pinlayer)
      # any shapes will be pushed into this array later
      my @tmpRecord = (0, 0, $temp[1], $temp[2], $movetype, $DEF_PIN_METAL_LAYER);
      $ref_ObjectDB->{obj_record}{$temp[0]} = \@tmpRecord;
    }
  }
  
  close(NODESFILE);
  
  $ref_ObjectDB->{fixed_nodes} = $fixed;
  $ref_ObjectDB->{nifixed_nodes} = $nifixed;
  
  die "NumNodes($ref_ObjectDB->{num_nodes}) does not match Num_Node_Records($num_node_records)\n"
  if($num_node_records != $ref_ObjectDB->{num_nodes});
  if($ref_ObjectDB->{num_terminals} != $ref_ObjectDB->{fixed_nodes}+$ref_ObjectDB->{nifixed_nodes})
  {
    my $temp_str = "NumTerminals($ref_ObjectDB->{num_terminals}) does not match ".
                   "Terminal($ref_ObjectDB->{fixed_nodes})+Terminal_NI($ref_ObjectDB->{nifixed_nodes})\n";
    die "$temp_str";
  }
  
  if($VERBOSE)
  {
    print "         Total Nodes             : $ref_ObjectDB->{num_nodes}\n";
    print "         Terminal Nodes          : $ref_ObjectDB->{num_terminals}\n";
    print "         Fixed Terminal Nodes    : $ref_ObjectDB->{fixed_nodes}\n";
    print "         Fixed_NI Terminal Nodes : $ref_ObjectDB->{nifixed_nodes}\n";
  }
}

###################################
# .shapes file processing
##################################
sub read_shapes_file {
  my ($shapes_file, $ref_ObjectDB) = @_;
  my ($temp, @temp, $num_nr_nodes);
  
  print "Phase 2: .shapes file\n" if($VERBOSE);
  
  open(SHAPESFILE, $shapes_file) or die "Can't open: $shapes_file ($!)\n";
  
  my $num_nr_records = 0;
  while(<SHAPESFILE>)
  {
    $_ = process_line($_);
    if(/^(shapes)/ or /^\s*$/ or /^#.*/)
    {
      next;
    }
    elsif(/^(NumNonRectangularNodes)/)
    {
      ($temp, $num_nr_nodes) = split ":";
      $num_nr_nodes = process_line($num_nr_nodes);
    }
    else
    {
      $num_nr_records++;
      my ($name, $num_shapes) = split ":";
      $name = process_line($name);
      $num_shapes = process_line($num_shapes);
      die "Invalid object ($name) in .shapes file\n" 
      if(!defined($ref_ObjectDB->{obj_record}{$name}));
      
      my $shape_id = 0;
      my %shapes;
      while(<SHAPESFILE>)
      {
        $_ = process_line($_);
        if(/^\s*$/ or /^#.*/)
        {
          next;
        }
        else
        {
          $shape_id++;
          @temp = split;
          my @tmpRecord = ($temp[1], $temp[2], $temp[3], $temp[4]);
          $shapes{$shape_id} = \@tmpRecord;
          last if($shape_id == $num_shapes);
        }
      }
      push(@{$ref_ObjectDB->{obj_record}{$name}}, \%shapes);
    }
  }
  
  close(SHAPESFILE);
  
  die "NumNonRectangularNodes($num_nr_nodes) does not match Num_NR_Records($num_nr_records)\n"
  if($num_nr_nodes != $num_nr_records);
  
  if($VERBOSE)
  {
    print "         Total Non-Rectangular Nodes  : $num_nr_records\n";
  }
}

###################################
# solution .pl file processing
##################################
sub read_pl_file {
  my ($pl_file, $ref_ObjectDB) = @_;
  my ($temp_ct, @temp);
  
  print "Phase 3: .pl file\n" if($VERBOSE);
  
  open(PLFILE, $pl_file) or die "Can't open: $pl_file ($!)\n";
  
  my $num_loc_records = 0;
  while(<PLFILE>)
  {
    $_ = process_line($_);
    if(/^(UCLA)/ or /^\s*$/ or /^#.*/)
    {
      next;
    }
    else
    {
      $num_loc_records++;
      @temp = split;
      $temp_ct = @temp;
      die "Invalid object ($temp[0]) in .pl file\n" 
      if(!defined($ref_ObjectDB->{obj_record}{$temp[0]}));
      
      ${$ref_ObjectDB->{obj_record}{$temp[0]}}[$XLOWINDEX] = $temp[1];
      ${$ref_ObjectDB->{obj_record}{$temp[0]}}[$YLOWINDEX] = $temp[2];
    }
  }
  
  close(PLFILE);
  
  die "NumNodes($ref_ObjectDB->{num_nodes}) does not match Num_Loc_Records($num_loc_records)\n"
  if($ref_ObjectDB->{num_nodes} != $num_loc_records);
  
  if($VERBOSE)
  {
    print "         Total Nodes  : $num_loc_records\n";
  }
}

###########################
# .nets file processing
###########################
sub read_nets_file {
  my ($nets_file, $ref_ObjectDB, $ref_NetDB) = @_;
  my ($temp, $temp_ct, @temp);
  
  print "Phase 4: .nets file\n" if($VERBOSE);
  
  open(NETSFILE, $nets_file) or die "Can't open: $nets_file ($!)\n";
  
  $ref_NetDB->{tot_wl} = 0;
  
  my $num_net_record = 0;
  my $num_pin_record = 0;
  while(<NETSFILE>)
  {
    $_ = process_line($_);
    if(/^(UCLA)/ or /^\s*$/ or /^#.*/)
    {
      next;
    }
    elsif(/^(NumNets)/)
    {
      ($temp, $ref_NetDB->{num_nets}) = split ":";
      $ref_NetDB->{num_nets} = process_line($ref_NetDB->{num_nets});
    }
    elsif(/^(NumPins)/)
    {
      ($temp, $ref_NetDB->{num_pins}) = split ":";
      $ref_NetDB->{num_pins} = process_line($ref_NetDB->{num_pins});
    }
    elsif(/^(NetDegree)/)
    {
      @temp = split;
      $temp_ct = @temp;
      my $degree = $temp[2];
      my $net_name;
      if($temp_ct < 4)
      {
        $net_name = "noname_net_$num_net_record";
      }
      else
      {
        $net_name = $temp[3];
      }
      $ref_NetDB->{net_record}{$net_name}{degree} = $degree;
      $ref_NetDB->{net_record}{$net_name}{index}  = $num_net_record;
      my $pin_id = 0;
      my %pins;
      my $this_net_lx = $MAX_VAL;
      my $this_net_ly = $MAX_VAL;
      my $this_net_hx = $MIN_VAL;
      my $this_net_hy = $MIN_VAL;
      while(<NETSFILE>)
      {
        $_ = process_line($_);
        if(/^\s*$/ or /^#.*/)
        {
          next;
        }
        else
        {
          $pin_id++;
          # assume line is: o464240   O  :     -1.0000      0.5000
          @temp = split;
          die "Invalid object ($temp[0]) in .nets file\n"
          if(!defined($ref_ObjectDB->{obj_record}{$temp[0]}));
          
          my $obj_lx = ${$ref_ObjectDB->{obj_record}{$temp[0]}}[$XLOWINDEX];
          my $obj_ly = ${$ref_ObjectDB->{obj_record}{$temp[0]}}[$YLOWINDEX];
          my $obj_dx = ${$ref_ObjectDB->{obj_record}{$temp[0]}}[$DXINDEX];
          my $obj_dy = ${$ref_ObjectDB->{obj_record}{$temp[0]}}[$DYINDEX];
          my $pin_x  = $obj_lx + ($obj_dx/2) + $temp[3];
          my $pin_y  = $obj_ly + ($obj_dy/2) + $temp[4];
          $pin_x = round_up_int($pin_x);
          $pin_y = round_up_int($pin_y);
          
          my @tmpPinRecord = ($temp[0], $pin_x, $pin_y);
          $pins{$pin_id} = \@tmpPinRecord;
          
          $this_net_lx = $pin_x if($pin_x < $this_net_lx);
          $this_net_ly = $pin_y if($pin_y < $this_net_ly);
          $this_net_hx = $pin_x if($pin_x > $this_net_hx);
          $this_net_hy = $pin_y if($pin_y > $this_net_hy);
          
          last if($pin_id == $degree);
        }
      }
      
      $num_pin_record += $pin_id;
      my $this_net_wl = (($this_net_hx - $this_net_lx) + ($this_net_hy - $this_net_ly));
      die "Net ($net_name) has negative HPWL ($this_net_wl)\n"
      if($this_net_wl < 0);
      
      $ref_NetDB->{net_record}{$net_name}{net_pins} = \%pins;
      $ref_NetDB->{tot_wl} += $this_net_wl;
      $num_net_record++;
    }
    else
    {
      next;
    }
  }
  
  close(NETSFILE);
  
  die "NumNets($ref_NetDB->{num_nets}) does not match Num_Net_Records($num_net_record)\n"
  if($ref_NetDB->{num_nets} != $num_net_record);
  
  die "NumPins($ref_NetDB->{num_pins}) does not match Num_Pin_Records($num_pin_record)\n"
  if($ref_NetDB->{num_pins} != $num_pin_record);
  
  if($VERBOSE)
  {
    print "         Total Nets         : $ref_NetDB->{num_nets}\n";
    print "         Total Pins         : $ref_NetDB->{num_pins}\n";
  }
}

###########################
# .route file processing
###########################
sub read_route_file {
  my ($route_file, $ref_ObjectDB, $ref_RouteDB) = @_;
  my ($temp, @temp, $num_ni_terminals, $num_route_blockages);
  
  print "Phase 5: .route file\n" if($VERBOSE);
  
  open(ROUTEFILE, $route_file) or die "Can't open: $route_file ($!)\n";
  
  while(<ROUTEFILE>)
  {
    $_ = process_line($_);
    if(/^(route)/ or /^\s*$/ or /^#.*/)
    {
      next;
    }
    elsif(/^(GridOrigin)/)
    {
      @temp = split;
      $ref_RouteDB->{origin_x} = $temp[2];
      $ref_RouteDB->{origin_y} = $temp[3];
    }
    elsif(/^(Grid)/)
    {
      @temp = split;
      $ref_RouteDB->{grid_x} = $temp[2];
      $ref_RouteDB->{grid_y} = $temp[3];
      $ref_RouteDB->{num_layers} = $temp[4];
    }    
    elsif(/^(VerticalCapacity)/) #get VerticalCapacity of a layer. 
    {
      @temp = split ":";
      $temp[1] = process_line($temp[1]);
      my @tmpRecord = split /\s+/, $temp[1];
      $ref_RouteDB->{v_capacity} = \@tmpRecord;
    }
    elsif(/^(HorizontalCapacity)/)
    {
      @temp = split ":";
      $temp[1] = process_line($temp[1]);
      my @tmpRecord = split /\s+/, $temp[1];
      $ref_RouteDB->{h_capacity} = \@tmpRecord;
    }
    elsif(/^(MinWireWidth)/)
    {
      @temp = split ":";
      $temp[1] = process_line($temp[1]);
      my @tmpRecord = split /\s+/, $temp[1];
      $ref_RouteDB->{wire_width} = \@tmpRecord;
    }
    elsif(/^(MinWireSpacing)/)
    {
      @temp = split ":";
      $temp[1] = process_line($temp[1]);
      my @tmpRecord = split /\s+/, $temp[1];
      $ref_RouteDB->{wire_spacing} = \@tmpRecord;
    }
    elsif(/^(ViaSpacing)/)
    {
      @temp = split ":";
      $temp[1] = process_line($temp[1]);
      my @tmpRecord = split /\s+/, $temp[1];
      $ref_RouteDB->{via_spacing} = \@tmpRecord;
    }
    elsif(/^(TileSize)/)
    {
      @temp = split;
      $ref_RouteDB->{tile_size_x} = $temp[2];
      $ref_RouteDB->{tile_size_y} = $temp[3];
    }
    elsif(/^(BlockagePorosity)/)
    {
      @temp = split;
      $ref_RouteDB->{blockage_porosity} = $temp[2];
    }
    elsif(/^(NumNiTerminals)/)
    {
      ($temp, $num_ni_terminals) = split ":";
      $num_ni_terminals = process_line($num_ni_terminals);
      
      if($ref_ObjectDB->{nifixed_nodes} != $num_ni_terminals)
      {
        my $temp_str = "Terminal_NI mismatch. ".
                       "From .nodes file ($ref_ObjectDB->{nifixed_nodes}) ".
                       "From .route file ($num_ni_terminals)\n";
        die $temp_str;
      }
      
      # get the metal layer for all pins on NIFIXED objects
      my $num_nifixed_records = 0;
      while(<ROUTEFILE>)
      {
        $_ = process_line($_);
        if(/^\s*$/ or /^#.*/)
        {
          next;
        }
        else
        {
          $num_nifixed_records++;
          @temp = split;
          die "Invalid object ($temp[0]) in .route file (Terminal_NI)\n"
          if(!defined($ref_ObjectDB->{obj_record}{$temp[0]}));
          
          ${$ref_ObjectDB->{obj_record}{$temp[0]}}[$PINLAYERINDEX] = $temp[1];
          last if($num_nifixed_records == $num_ni_terminals);
        }
      }
    }
    elsif(/^(NumBlockageNodes)/)
    {
      ($temp, $num_route_blockages) = split ":";
      $num_route_blockages = process_line($num_route_blockages);
      
      # get the blockage layer information
      my $num_blockage_records = 0;
      while(<ROUTEFILE>)
      {
        $_ = process_line($_);
        if(/^\s*$/ or /^#.*/)
        {
          next;
        }
        else
        {
          $num_blockage_records++;
          my ($name, @tmpRecord) = split;
          die "Invalid object ($name) in .route file (Blockage)\n"
          if(!defined($ref_ObjectDB->{obj_record}{$name}));
          
          $ref_RouteDB->{blockage}{$name} = \@tmpRecord;
          last if($num_blockage_records == $num_route_blockages);
        }
      }
    }
    else
    {
      next;
    }
  }
  
  close(ROUTEFILE);
  
  if($VERBOSE)
  {
    print "         Num Layers        : $ref_RouteDB->{num_layers}\n";
    print "         Grid              : $ref_RouteDB->{grid_x} X $ref_RouteDB->{grid_y}\n";
    print "         Tile Size         : $ref_RouteDB->{tile_size_x} X $ref_RouteDB->{tile_size_y}\n";
    print "         Num Terminal_NI   : $num_ni_terminals\n";
    print "         Num Blockages     : $num_route_blockages\n";
    print "         Blockage Porosity : $ref_RouteDB->{blockage_porosity}\n";
  }
}

#####################################
# get tile edge capacities per layer
#####################################
sub get_tile_capacity {
  my ($ref_ObjectDB, $ref_NetDB, $ref_RouteDB, $ref_TileCapacityDB) = @_;
  my (@capl, @capr, @capt, @capb, $x, $y, $z, $i);
  
  print "Phase 6: get tile capacities\n" if($VERBOSE);
  
  my $grid_x = $ref_RouteDB->{grid_x};
  my $grid_y = $ref_RouteDB->{grid_y};
  my $grid_z = $ref_RouteDB->{num_layers};
  my $origin_x = $ref_RouteDB->{origin_x};
  my $origin_y = $ref_RouteDB->{origin_y};
  my $tile_size_x = $ref_RouteDB->{tile_size_x};
  my $tile_size_y = $ref_RouteDB->{tile_size_y};
  my @v_capacity = @{$ref_RouteDB->{v_capacity}};
  my @h_capacity = @{$ref_RouteDB->{h_capacity}};
  my @wire_width = @{$ref_RouteDB->{wire_width}};
  my @wire_spacing = @{$ref_RouteDB->{wire_spacing}};
  
  # initialize with maximum allowed capacity
  for $x (0 .. ($grid_x-1))
  {
    for $y (0 .. ($grid_y-1))
    {
      for $z (0 .. ($grid_z-1))
      {
        $capl[$x][$y][$z] = ($x != 0) ? $h_capacity[$z] : 0;
        $capr[$x][$y][$z] = ($x != $grid_x - 1) ? $h_capacity[$z] : 0;  
        $capt[$x][$y][$z] = ($y != $grid_y - 1) ? $v_capacity[$z] : 0;
        $capb[$x][$y][$z] = ($y != 0) ? $v_capacity[$z] : 0;
      }
    }
  }
  
  # process tile capacity adjustment section
  my %TileOverlapDB;
  my $num_blockages = 0;
  my %debug_shapes;
  
  if(scalar(keys(%{$ref_RouteDB->{blockage}})) > 0)
  {
    # get the blockage overlaps with the tile edges
    foreach my $name (keys(%{$ref_RouteDB->{blockage}}))
    {
      $num_blockages++;
      my @tmpRecord = @{$ref_RouteDB->{blockage}{$name}};
      # $tmpRecord[0] gives the total number of blocked layers
      # for each layer blocked by this object get the 
      # corresponding overlap with the tile edges
      for($i=1; $i<=$tmpRecord[0]; $i++)
      {
        my $layer = $tmpRecord[$i];
        # do not perform any capacity adjustment 
        # if the layer is completely blocked
        next if(($h_capacity[$layer-1] <= 0) && ($v_capacity[$layer-1] <= 0));
        
        my ($obj_lx, $obj_ly, $obj_dx, $obj_dy);
        my $temp_ct = @{$ref_ObjectDB->{obj_record}{$name}};
        if($temp_ct == $SHAPEINDEX+1)
        {
          # this is a non-rectangular object
          my %shapes = %{${$ref_ObjectDB->{obj_record}{$name}}[$SHAPEINDEX]};
          die "Incorrect shapes information for object($name).\n"
          if(scalar(keys(%shapes)) <= 0);
          
          foreach my $shape_id (sort(keys(%shapes)))
          {
            if(defined($debug_shapes{$name}{$shape_id}))
            {
              $debug_shapes{$name}{$shape_id} += 1;
            }
            else
            {
              $debug_shapes{$name}{$shape_id} = 1;
            }
            $obj_lx = ${$shapes{$shape_id}}[$XLOWINDEX];
            $obj_ly = ${$shapes{$shape_id}}[$YLOWINDEX];
            $obj_dx = ${$shapes{$shape_id}}[$DXINDEX];
            $obj_dy = ${$shapes{$shape_id}}[$DYINDEX];
            get_blockage_overlap($obj_lx, $obj_ly, $obj_dx, $obj_dy, 
                                 $layer, $ref_RouteDB, \%TileOverlapDB);
          }
        }
        else
        {
          # this is a rectangular object
          $obj_lx = ${$ref_ObjectDB->{obj_record}{$name}}[$XLOWINDEX];
          $obj_ly = ${$ref_ObjectDB->{obj_record}{$name}}[$YLOWINDEX];
          $obj_dx = ${$ref_ObjectDB->{obj_record}{$name}}[$DXINDEX];
          $obj_dy = ${$ref_ObjectDB->{obj_record}{$name}}[$DYINDEX];
          get_blockage_overlap($obj_lx, $obj_ly, $obj_dx, $obj_dy, 
                               $layer, $ref_RouteDB, \%TileOverlapDB);
        }
      } # for each blocked layer
    } # for each blockage object
    
    # for each key_string, sort the associated blockages 
    # in non-decreasing order of the lower-x(y) coordinate
    foreach my $key_string (sort(keys(%TileOverlapDB)))
    {
      my @sorted_array = sort sort_ascending @{$TileOverlapDB{$key_string}};
      splice(@{$TileOverlapDB{$key_string}});
      @{$TileOverlapDB{$key_string}} = @sorted_array;
    }
  } # end(if(blockage))
  
  # get the total blockage overlap per tile edge
  my %TileBlockageDB;
  
  if(scalar(keys(%TileOverlapDB)) > 0)
  {
    foreach my $key_string (sort(keys(%TileOverlapDB)))
    {
      my $occupied = 0;
      if(scalar(@{$TileOverlapDB{$key_string}}) > 1)
      {
        # there is more than one blockage overlapping with tile edge
        my (@this_node, $left, $right);
        @this_node = split/:+/, ${$TileOverlapDB{$key_string}}[0];
        $left  = $this_node[0];
        $right = $this_node[1];
        
        for my $index (1 .. $#{$TileOverlapDB{$key_string}})
        {
          @this_node = split/:+/, ${$TileOverlapDB{$key_string}}[$index];
          if(($right <= $this_node[0]) || ($left >= $this_node[1]))
          {
            # no overlap
            $occupied += $right - $left;
            $left  = $this_node[0];
            $right = $this_node[1];
          }
          else
          {
            # overlap
            $left  = min($left,  $this_node[0]);
            $right = max($right, $this_node[1]);
          }
        }
        
        $occupied += $right - $left;
      }
      else
      {
        # there is a single blockage overlapping with the tile edge
        my @this_node = split/:+/, ${$TileOverlapDB{$key_string}}[0];
        $occupied = $this_node[1] - $this_node[0];
      }
      
      $TileBlockageDB{$key_string} = $occupied;
    }
  } # end(if(TileOverlapDB))
  
  # adjust tile edge capacities based on the blockages
  my $num_cap_adjustment = scalar(keys(%TileBlockageDB));
  
  my $num_adjust_record = 0;
  foreach my $key_string (sort(keys(%TileBlockageDB)))
  {
    $num_adjust_record++;
    my @tmpRecord = split/:+/, $key_string;
    my $col = $tmpRecord[0];
    my $row = $tmpRecord[1];
    my $dir = $tmpRecord[2];
    my $layer = $tmpRecord[3];
    my $val = $TileBlockageDB{$key_string};
    my $blocked = int((1.0 - $ref_RouteDB->{blockage_porosity}) * $val);
    
    if($dir eq "H")
    # reduce capacity for horizontal routes
    {
      die "Max H_Capacity for layer($layer) is zero.\n"
      if($h_capacity[$layer-1] <= 0);
      
      my $max_capacity = $h_capacity[$layer-1];
      my $max_space = $tile_size_y;
      my $available_space = ($max_space - $blocked) / $max_space;
      my $adjusted_capacity = int($max_capacity * $available_space);
      $adjusted_capacity = max(0, $adjusted_capacity);
      my $wire_width   = $wire_width[$layer-1];
      my $wire_spacing = $wire_spacing[$layer-1];
      my $num_tracks = int($adjusted_capacity / ($wire_width + $wire_spacing));
      $adjusted_capacity = $num_tracks * ($wire_width + $wire_spacing);
      
      $capr[$col][$row][$layer-1]   = $adjusted_capacity;
      $capl[$col+1][$row][$layer-1] = $adjusted_capacity;
    }
    elsif($dir eq "V")
    # reduce capacity for vertical routes
    {
      die "Max V_Capacity for layer($layer) is zero.\n"
      if($v_capacity[$layer-1] <= 0);
      
      my $max_capacity = $v_capacity[$layer-1];
      my $max_space = $tile_size_x;
      my $available_space = ($max_space - $blocked) / $max_space;
      my $adjusted_capacity = int($max_capacity * $available_space);
      $adjusted_capacity = max(0, $adjusted_capacity);
      my $wire_width   = $wire_width[$layer-1];
      my $wire_spacing = $wire_spacing[$layer-1];
      my $num_tracks = int($adjusted_capacity / ($wire_width + $wire_spacing));
      $adjusted_capacity = $num_tracks * ($wire_width + $wire_spacing);
      
      $capt[$col][$row][$layer-1]   = $adjusted_capacity;
      $capb[$col][$row+1][$layer-1] = $adjusted_capacity;
    }
    else
    {
      die "Incorrect direction for capacity adjustment\n";
    }
  }
  
  die "Num_Cap_Adjustment($num_cap_adjustment) != Num_Adjust_Records($num_adjust_record)\n"
  if($num_cap_adjustment != $num_adjust_record);
  
  my $num_nr_nodes = scalar(keys(%debug_shapes));
  my $num_nr_shapes = 0;
  foreach my $name (keys(%debug_shapes))
  {
    $num_nr_shapes += scalar(keys(%{$debug_shapes{$name}}));
  }
  
  if($VERBOSE)
  {
    print "         Num Blockages Processed   : $num_blockages\n";
    print "         Num Non-rectangular nodes : $num_nr_nodes\n";
    print "             Num Shapes processed  : $num_nr_shapes\n";
    print "         Num Capacity Adjustments  : $num_cap_adjustment\n";
  }
  
  if($VERBOSE > 1)
  {
    for $z (0 .. ($grid_z-1)) {
      my $layer_id = $z + 1;
      print "== Layer: $layer_id ==\n";
      for $x (0 .. ($grid_x-1)) {
        for $y (0 .. ($grid_y-1)) {
          print "($x, $y):  ";
          print "$capl[$x][$y][$z]  ";
          print "$capr[$x][$y][$z]  ";
          print "$capb[$x][$y][$z]  ";
          print "$capt[$x][$y][$z]\n";
        }
      }
    }
  }
  
  $ref_TileCapacityDB->{L} = \@capl;
  $ref_TileCapacityDB->{R} = \@capr;
  $ref_TileCapacityDB->{T} = \@capt;
  $ref_TileCapacityDB->{B} = \@capb;
}

sub get_blockage_overlap {
  my $obj_lx      = $_[0];
  my $obj_ly      = $_[1];
  my $obj_dx      = $_[2];
  my $obj_dy      = $_[3];
  my $layer       = $_[4];
  my $ref_RouteDB = $_[5];
  my $ref_TileOverlapDB = $_[6];
  
  my $grid_x = $ref_RouteDB->{grid_x};
  my $grid_y = $ref_RouteDB->{grid_y};
  my $origin_x = $ref_RouteDB->{origin_x};
  my $origin_y = $ref_RouteDB->{origin_y};
  my $tile_width = $ref_RouteDB->{tile_size_x};
  my $tile_height = $ref_RouteDB->{tile_size_y};
  my @v_capacity = @{$ref_RouteDB->{v_capacity}};
  my @h_capacity = @{$ref_RouteDB->{h_capacity}};
  
  # chop the blockage if it extends beyond the routing grid
  if(($obj_lx + $obj_dx) > ($origin_x + $grid_x*$tile_width))
  {
    $obj_dx = $origin_x + $grid_x*$tile_width - $obj_lx;
  }
  if($obj_lx < $origin_x)
  {
    $obj_dx -= ($origin_x - $obj_lx);
    $obj_lx = $origin_x;
  }
  if(($obj_ly + $obj_dy) > ($origin_y + $grid_y*$tile_height))
  {
    $obj_dy = $origin_y + $grid_y*$tile_height - $obj_ly;
  }
  if($obj_ly < $origin_y)
  {
    $obj_dy -= ($origin_y - $obj_ly);
    $obj_ly = $origin_y;
  }
  
  my $obj_hx = $obj_lx + $obj_dx;
  my $obj_hy = $obj_ly + $obj_dy;
  
  # grids spanned by the blockage
  my $lx_index = int(($obj_lx - $origin_x)/$tile_width);
  my $ly_index = int(($obj_ly - $origin_y)/$tile_height);
  my $hx_index = int(($obj_hx - $origin_x)/$tile_width);
  my $hy_index = int(($obj_hy - $origin_y)/$tile_height);
  
  # if the blockage abuts any of the grid boundaries
  if($obj_lx == ($lx_index*$tile_width + $origin_x))
  {
    $lx_index--;
  }
  if($obj_ly == ($ly_index*$tile_height + $origin_y))
  {
    $ly_index--;
  }
  
  # grid boundaries
  $lx_index = min($grid_x-1, max(0, $lx_index));
  $ly_index = min($grid_y-1, max(0, $ly_index));
  $hx_index = min($grid_x-1, max(0, $hx_index));
  $hy_index = min($grid_y-1, max(0, $hy_index));
  
  # is it a horizontal or vertical blockage
  my $layer_string;
  if($h_capacity[$layer-1] > 0)
  {
    $layer_string = "H";
  }
  elsif($v_capacity[$layer-1] > 0)
  {
    $layer_string = "V";
  }
  else
  {
    print "WARNING: Layer($layer) has zero capacity.\n" if($VERBOSE > 1);
    return;
  }
  
  my ($x, $y, $index_string, @v_bounds, @h_bounds, $left, $right);
  # generate blockage overlap for vertical routes
  if(($layer_string eq "V") && ($hy_index > $ly_index))
  {
    # get the overlapping horizontal bounds per tile
    if($hx_index == $lx_index)
    {
      $v_bounds[0] = "$obj_lx:$obj_hx";
    }
    else
    {
      $left  = $obj_lx;
      $right = ($lx_index+1)*$tile_width + $origin_x;
      $v_bounds[0] = "$left:$right";
      
      $left  = $hx_index*$tile_width + $origin_x;
      $right = $obj_hx;
      $v_bounds[$hx_index-$lx_index] = "$left:$right";
      
      for($x=$lx_index+1; $x<$hx_index; $x++)
      {
        $left  = $x*$tile_width + $origin_x;
        $right = ($x+1)*$tile_width + $origin_x;
        $v_bounds[$x-$lx_index] = "$left:$right";
      }
    }
    # get blockage overlap per tile edge
    for($x=$lx_index; $x<=$hx_index; $x++)
    {
      my @temp = split/:+/, $v_bounds[$x-$lx_index];
      next if($temp[0] >= $temp[1]);
      
      for($y=$ly_index; $y<$hy_index; $y++)
      {
        $index_string = "$x:$y:$layer_string:$layer";
        if(!defined($ref_TileOverlapDB->{$index_string}))
        {
          my @tmpRecord = ($v_bounds[$x-$lx_index]);
          $ref_TileOverlapDB->{$index_string} = \@tmpRecord;
        }
        else
        {
          push @{$ref_TileOverlapDB->{$index_string}}, $v_bounds[$x-$lx_index];
        }
      }
    }
  }
  # generate blockage overlap for horizontal routes
  elsif(($layer_string eq "H") && ($hx_index > $lx_index))
  {
    # get the overlapping vertical bounds per tile
    if($hy_index == $ly_index)
    {
      $h_bounds[0] = "$obj_ly:$obj_hy";
    }
    else
    {
      $left  = $obj_ly;
      $right = ($ly_index+1)*$tile_height + $origin_y;
      $h_bounds[0] = "$left:$right";
      
      $left  = $hy_index*$tile_height + $origin_y;
      $right = $obj_hy;
      $h_bounds[$hy_index-$ly_index] = "$left:$right";
      
      for($y=$ly_index+1; $y<$hy_index; $y++)
      {
        $left  = $y*$tile_height + $origin_y;
        $right = ($y+1)*$tile_height + $origin_y;
        $h_bounds[$y-$ly_index] = "$left:$right";
      }
    }
    # get blockage overlap per tile edge
    for($y=$ly_index; $y<=$hy_index; $y++)
    {
      my @temp = split/:+/, $h_bounds[$y-$ly_index];
      next if($temp[0] >= $temp[1]);
      
      for($x=$lx_index; $x<$hx_index; $x++)
      {
        $index_string = "$x:$y:$layer_string:$layer";
        if(!defined($ref_TileOverlapDB->{$index_string}))
        {
          my @tmpRecord = ($h_bounds[$y-$ly_index]);
          $ref_TileOverlapDB->{$index_string} = \@tmpRecord;
        }
        else
        {
          push @{$ref_TileOverlapDB->{$index_string}}, $h_bounds[$y-$ly_index];
        }
      }
    }
  }
  else
  {
    # no capacity adjustment required (blockage is completely within tile)
  }
}

#########################################
# get tile demand and net routes
#########################################
sub read_routing_solution {
  my $route_file        = $_[0];
  my $ref_ObjectDB      = $_[1];
  my $ref_NetDB         = $_[2];
  my $ref_RouteDB       = $_[3];
  my $ref_TileDemandDB  = $_[4];
  my $ref_NetRouteDB    = $_[5];
  
  my $grid_x = $ref_RouteDB->{grid_x};
  my $grid_y = $ref_RouteDB->{grid_y};
  my $grid_z = $ref_RouteDB->{num_layers};
  my $origin_x = $ref_RouteDB->{origin_x};
  my $origin_y = $ref_RouteDB->{origin_y};
  my $tile_size_x = $ref_RouteDB->{tile_size_x};
  my $tile_size_y = $ref_RouteDB->{tile_size_y};
  my @wire_width = @{$ref_RouteDB->{wire_width}};
  my @wire_spacing = @{$ref_RouteDB->{wire_spacing}};
  
  print "Phase 7: read routing solution\n" if($VERBOSE);
  
  my $num_ext_nets = 0;   # Nets spanning g-cells
  my $num_int_nets = 0;   # Nets within a g-cell
  my $num_net_record = 0;
  foreach my $net_name (sort(keys(%{$ref_NetDB->{net_record}})))
  {
    $num_net_record++;
    $ref_NetDB->{net_record}{$net_name}{is_routed} = 0;
    my ($test_row, $test_col, $row, $col);
    my $is_ext_net = 0;
    my %pins = %{$ref_NetDB->{net_record}{$net_name}{net_pins}};
    foreach my $pin_id (sort(keys(%pins)))
    {
      my @tmpRecord = @{$pins{$pin_id}};
      my $pin_x = $tmpRecord[1];
      my $pin_y = $tmpRecord[2];
      if($pin_id == 1)
      {
        $test_row = int(($pin_y - $origin_y) / $tile_size_y);
        $test_col = int(($pin_x - $origin_x) / $tile_size_x);
      }
      else
      {
        $row = int(($pin_y - $origin_y) / $tile_size_y);
        $col = int(($pin_x - $origin_x) / $tile_size_x);
        if(($row != $test_row) || ($col != $test_col))
        {
          $is_ext_net = 1;
          last;
        }
      }
    }
    if($is_ext_net)
    {
      $num_ext_nets++;
      $ref_NetDB->{net_record}{$net_name}{gr_net} = 1;
    }
    else
    {
      $num_int_nets++;
      $ref_NetDB->{net_record}{$net_name}{gr_net} = 0;
    }
  }
  
  if($VERBOSE)
  {
    print "         Total Nets            : $num_net_record\n";
    print "         Nets within a g-cell  : $num_int_nets\n";
    print "         Nets spanning g-cells : $num_ext_nets\n";
  }
  
  # get the total number of pins in each tile
  my (@tile_pins, $x, $y);
  for $x (0 .. ($grid_x-1))
  {
    for $y (0 .. ($grid_y-1))
    {
      $tile_pins[$x][$y] = 0;
    }
  }
  
  my $temp_net_record = 0;
  foreach my $net_name (sort(keys(%{$ref_NetDB->{net_record}})))
  {
    $temp_net_record++;
    my %pins = %{$ref_NetDB->{net_record}{$net_name}{net_pins}};
    foreach my $pin_id (sort(keys(%pins)))
    {
      my @tmpRecord = @{$pins{$pin_id}};
      my $pin_x = $tmpRecord[1];
      my $pin_y = $tmpRecord[2];
      my $tile_x = int(($pin_x - $origin_x) / $tile_size_x);
      my $tile_y = int(($pin_y - $origin_y) / $tile_size_y);
      $tile_pins[$tile_x][$tile_y] += 1;
    }
  }
  
  $ref_RouteDB->{tile_pins} = \@tile_pins;
  
  die "NumNets($ref_NetDB->{num_nets}) != Num_Net_Records($temp_net_record)\n"
  if($ref_NetDB->{num_nets} != $temp_net_record);
  
  # read the routing solution and get tile demand
  my (@deml, @demr, @demt, @demb, $x, $y, $z);
  for $x (0 .. ($grid_x-1))
  {
    for $y (0 .. ($grid_y-1))
    {
      for $z (0 .. ($grid_z-1))
      {
        $deml[$x][$y][$z] = 0;
        $demr[$x][$y][$z] = 0;
        $demt[$x][$y][$z] = 0;
        $demb[$x][$y][$z] = 0;
      }
    }
  }
  
  open(ROUTEFILE, $route_file) or die "Can't open: $route_file ($!)\n";
  
  my (%cons, %endp, $routes, %visit, @vq, $nottree, %blind);
  my $num_routed_nets = 0;
  while(<ROUTEFILE>)
  {
    $_ = process_line($_);
    next if(/^\s*$/);
    
    my @temp = split;
    die "Bad line in routing solution file.\n" if(scalar(@temp) <= 0);
    die "Invalid net ($temp[0]) in routing solution file.\n" 
    if(!defined($ref_NetDB->{net_record}{$temp[0]}));
    
    my $net_name = $temp[0];
    $ref_NetDB->{net_record}{$net_name}{is_routed} = 1;
    $num_routed_nets++;
    %cons = ();
    %endp = ();
    $routes = "";
    while(<ROUTEFILE>)
    {
      last if(/^\s*!\s*$/);
      
      # do not consider intra-gcell nets during analysis
      next if($ref_NetDB->{net_record}{$net_name}{gr_net} == 0);
      
      die "Bad route for Net($net_name).\n" 
      unless(/\s*\((\d+),(\d+),(\d+)\)-\((\d+),(\d+),(\d+)\)/);
      
      my $x1 = $1;
      my $y1 = $2;
      my $l1 = $3 - 1;
      my $x2 = $4;
      my $y2 = $5;
      my $l2 = $6 - 1;
      $x1 = int(($x1 - $origin_x) / $tile_size_x);
      $y1 = int(($y1 - $origin_y) / $tile_size_y);
      $x2 = int(($x2 - $origin_x) / $tile_size_x);
      $y2 = int(($y2 - $origin_y) / $tile_size_y);
      my $wire_width   = $wire_width[$l1];
      my $wire_spacing = $wire_spacing[$l1];
      
      if($x1 != $x2)
      {
        die "Diagonal route for Net($net_name).\n" unless(($y1 == $y2) && ($l1 == $l2));
        #print "M1 route for Net($net_name).\n" if($l1 == 0);
        if($x2 < $x1)
        {
          my $t = $x1;
          $x1 = $x2;
          $x2 = $t;
        }
        for $x ($x1 .. ($x2 - 1))
        {
          my $t = $x + 1;
          my $s1 = "$x,$y1,$l1;";
          my $s2 = "$t,$y1,$l1;";
          $cons{$s1} .= $s2;
          $cons{$s2} .= $s1;
          $demr[$x][$y1][$l1] += ($wire_width + $wire_spacing);
          $deml[$t][$y1][$l1] += ($wire_width + $wire_spacing);
        }
      }
      elsif($y1 != $y2)
      {
        die "Diagonal route for Net($net_name).\n" unless(($x1 == $x2) && ($l1 == $l2));
        #print "M1 route for Net($net_name).\n" if($l1 == 0);
        if($y2 < $y1)
        {
          my $t = $y1;
          $y1 = $y2;
          $y2 = $t;
        }
        for $y ($y1 .. ($y2 - 1))
        {
          my $t = $y + 1;
          my $s1 = "$x1,$y,$l1;";
          my $s2 = "$x1,$t,$l1;";
          $cons{$s1} .= $s2;
          $cons{$s2} .= $s1;
          $demt[$x1][$y][$l1] += ($wire_width + $wire_spacing);
          $demb[$x1][$t][$l1] += ($wire_width + $wire_spacing);
        }
      }
      elsif($l1 != $l2)
      {
        die "Diagonal route for Net($net_name).\n" unless(($x1 == $x2) && ($y1 == $y2));
        if($l2 < $l1)
        {
          my $t = $l1;
          $l1 = $l2;
          $l2 = $t;
        }
        for $z ($l1 .. ($l2 - 1))
        {
          my $t = $z + 1;
          my $s1 = "$x1,$y1,$z;";
          my $s2 = "$x1,$y1,$t;";
          $cons{$s1} .= $s2;
          $cons{$s2} .= $s1;
        }
      }
      else
      {
        die "Null route for Net($net_name).\n";
      }
      $routes .= "$x1,$y1,$l1,$x2,$y2,$l2;";
      $endp{"$x1,$y1,$l1;"} = 1;
      $endp{"$x2,$y2,$l2;"} = 1;
    } #end(while)
    
    # If it is a net that spans g-cells
    if($ref_NetDB->{net_record}{$net_name}{gr_net} != 0)
    {
      if($CHECK_WIRES)
      {
        %visit = ();
        @vq = ();
        my %pins = %{$ref_NetDB->{net_record}{$net_name}{net_pins}};
        my @tmpRecord = @{$pins{1}};
        my $name  = $tmpRecord[0];
        my $x1 = $tmpRecord[1];
        my $y1 = $tmpRecord[2];
        my $l1 = ${$ref_ObjectDB->{obj_record}{$name}}[$PINLAYERINDEX];
        $x1 = int(($x1 - $origin_x) / $tile_size_x);
        $y1 = int(($y1 - $origin_y) / $tile_size_y);
        $l1 = $l1 - 1;
        my $t = "$x1,$y1,$l1;";
        push @vq, $t;
        $visit{$t} = "START";
        $nottree = 0;
        %blind = ();
        while($t = pop @vq)
        {
          my @cl = split ';', $cons{$t};
          for my $j (@cl)
          {
            $j .= ';';
            if(!defined($visit{$j}))
            {
              push @vq, $j;
              $visit{$j} = $t;
            }
            elsif($j ne $visit{$t})
            {
              $nottree = 1;
            }
          }
          $blind{$t} = 1 if($#cl <= 0);
          delete $endp{$t};
        }
        foreach my $pin_id (sort(keys(%pins)))
        {
          @tmpRecord = @{$pins{$pin_id}};
          $name  = $tmpRecord[0];
          $x1 = $tmpRecord[1];
          $y1 = $tmpRecord[2];
          $l1 = ${$ref_ObjectDB->{obj_record}{$name}}[$PINLAYERINDEX];
          $l1 = $l1 - 1;
          my $xg = int(($x1 - $origin_x) / $tile_size_x);
          my $yg = int(($y1 - $origin_y) / $tile_size_y);
          $t = "$xg,$yg,$l1;";
          if(!defined($visit{$t}))
          {
            my $tl = $l1 + 1;
            print "ERROR: Net($net_name) Pin($x1,$y1,$tl) is not attached.\n";
          }
          delete $blind{$t};
        }
        
        print "Disjoint Net($net_name).\n" if(keys(%endp));
        print "WARNING Net($net_name) has a cycle.\n" 
        if($nottree && $VERBOSE > 1);
        print "WARNING Net($net_name) has a blind route.\n" 
        if(keys(%blind) && $VERBOSE > 1);
      }
      
      $ref_NetRouteDB->{$net_name} = $routes;
    } # end(if(gr_net))
  }
  
  close(ROUTEFILE);
  
  if($VERBOSE)
  {
    print "         Routed Nets           : $num_routed_nets\n";
  }
  
  # check that all "external" nets are routed
  foreach my $net_name (sort(keys(%{$ref_NetDB->{net_record}})))
  {
    if(($ref_NetDB->{net_record}{$net_name}{gr_net} == 1) && 
       ($ref_NetDB->{net_record}{$net_name}{is_routed} == 0))
    {
        # print "ERROR: Net($net_name) spans g-cells but is not routed.\n";
    }
  }
  
  if($VERBOSE > 1)
  {
    for $z (0 .. ($grid_z-1)) {
      my $layer_id = $z + 1;
      print "== Layer: $layer_id ==\n";
      for $x (0 .. ($grid_x-1)) {
        for $y (0 .. ($grid_y-1)) {
          print "($x, $y):  ";
          print "$deml[$x][$y][$z]  ";
          print "$demr[$x][$y][$z]  ";
          print "$demb[$x][$y][$z]  ";
          print "$demt[$x][$y][$z]\n";
        }
      }
    }
  }
  
  $ref_TileDemandDB->{L} = \@deml;
  $ref_TileDemandDB->{R} = \@demr;
  $ref_TileDemandDB->{T} = \@demt;
  $ref_TileDemandDB->{B} = \@demb;
}

#########################################################
# evaluate the routing solution and get congestion stats
#########################################################
sub get_congestion_stats {
  my ($ref_RouteDB, $ref_TileCapacityDB, $ref_TileDemandDB, $ref_MetricsDB) = @_;
  my (@horAceArr, @verAceArr, @maxAceArr);
  my ($horCntEdges, $verCntEdges, @horEdgeCongArr, @verEdgeCongArr);
  my ($x, $y, $z);
  
  my $grid_x = $ref_RouteDB->{grid_x};
  my $grid_y = $ref_RouteDB->{grid_y};
  my $grid_z = $ref_RouteDB->{num_layers};
  my @wire_width = @{$ref_RouteDB->{wire_width}};
  my @wire_spacing = @{$ref_RouteDB->{wire_spacing}};
  $horCntEdges = $verCntEdges = 0;
  
  print "Phase 8: get congestion statistics\n" if($VERBOSE);
  
  for $z (0 .. ($grid_z-1))
  {
    # skip layer which is not available for routing
    next if((${$ref_RouteDB->{v_capacity}}[$z] == 0) && (${$ref_RouteDB->{h_capacity}}[$z] == 0));
    
    my $layerCapacity;
    my $verDir = 0;
    if(${$ref_RouteDB->{v_capacity}}[$z] != 0)
    {
      $verDir = 1;
      $layerCapacity = ${$ref_RouteDB->{v_capacity}}[$z];
    }
    else
    {
      $layerCapacity = ${$ref_RouteDB->{h_capacity}}[$z];
    }
    
    for $y (0 .. ($grid_y-1))
    {
      for $x (0 .. ($grid_x-1))
      {
        # Horizontal routes
        if($verDir == 0)
        {
          # blockage information
          my $blkg = $layerCapacity - ${$ref_TileCapacityDB->{R}}[$x][$y][$z];
          
          # pin blockage on layers M2 or M3
          my $pin_blkg = 0;
          if(($z == 1) || ($z == 2))
          {
            if($x < $grid_x-1)
            {
              $pin_blkg = ceil(${$ref_RouteDB->{tile_pins}}[$x][$y] * $PIN_BLOCKAGE_FACTOR) + 
                          ceil(${$ref_RouteDB->{tile_pins}}[$x+1][$y] * $PIN_BLOCKAGE_FACTOR);
            }
            else
            {
              $pin_blkg = ceil(${$ref_RouteDB->{tile_pins}}[$x][$y] * $PIN_BLOCKAGE_FACTOR);
            }
            $pin_blkg *= ($wire_width[$z] + $wire_spacing[$z]);
          }
          
          if($blkg < $IGNORE_EDGE_RATIO * $layerCapacity)
          {
            my $edgeCong = (${$ref_TileDemandDB->{R}}[$x][$y][$z] + $blkg + $pin_blkg) / $layerCapacity;
            $horCntEdges = $horCntEdges + 1;
            push(@horEdgeCongArr, $edgeCong);
          }
        }
        # Vertical routes
        else
        {
          # blockage information
          my $blkg = $layerCapacity - ${$ref_TileCapacityDB->{T}}[$x][$y][$z];
          
          # pin blockage on layers M2 or M3
          my $pin_blkg = 0;
          if(($z == 1) || ($z == 2))
          {
            if($y < $grid_y-1)
            {
              $pin_blkg = ceil(${$ref_RouteDB->{tile_pins}}[$x][$y] * $PIN_BLOCKAGE_FACTOR) + 
                          ceil(${$ref_RouteDB->{tile_pins}}[$x][$y+1] * $PIN_BLOCKAGE_FACTOR);
            }
            else
            {
              $pin_blkg = ceil(${$ref_RouteDB->{tile_pins}}[$x][$y] * $PIN_BLOCKAGE_FACTOR);
            }
            $pin_blkg *= ($wire_width[$z] + $wire_spacing[$z]);
          }
          
          if($blkg < $IGNORE_EDGE_RATIO * $layerCapacity)
          {
            my $edgeCong = (${$ref_TileDemandDB->{T}}[$x][$y][$z] + $blkg + $pin_blkg) / $layerCapacity;
            $verCntEdges = $verCntEdges + 1;
            push(@verEdgeCongArr, $edgeCong);
          }
        }
      }
    }
  } #end loop of z
  
  # calculate the average congestion metrics
  # sort numerically descending
  @horEdgeCongArr = sort {$b <=> $a} @horEdgeCongArr;
  @verEdgeCongArr = sort {$b <=> $a} @verEdgeCongArr;
  
  # calculate the average congestion
  foreach my $percentage (@ACE_PERCENT_ARRAY)
  {
    my $horNumEdgesCounted = int(($percentage*$horCntEdges)/100.0);
    my $horAvgCong = a_mean(@horEdgeCongArr[0..$horNumEdgesCounted]);
    push(@horAceArr, $horAvgCong);
    
    my $verNumEdgesCounted = int(($percentage*$verCntEdges)/100.0);
    my $verAvgCong = a_mean(@verEdgeCongArr[0..$verNumEdgesCounted]);
    push(@verAceArr, $verAvgCong);
  }
  
  # get the ACE vector corresponding to the maximum of 
  # the horizontal and vertical congestion values
  for(my $i=0; $i<@ACE_PERCENT_ARRAY; $i++)
  {
    $maxAceArr[$i] = max($horAceArr[$i], $verAceArr[$i]);
  }
  
  if($VERBOSE > 1)
  {
    print("ACE      ");
    printf("%6g%%  ", $_) foreach (@ACE_PERCENT_ARRAY);
    print("\n");
    
    print("Hor      ");
    printf("%.2lf   ", 100*$_) foreach(@horAceArr);
    print("\n");
    
    print("Ver      ");
    printf("%.2lf   ", 100*$_) foreach(@verAceArr);
    print("\n");
  }
  
  $ref_MetricsDB->{ACE_H}   = \@horAceArr;
  $ref_MetricsDB->{ACE_V}   = \@verAceArr;
  $ref_MetricsDB->{ACE_MAX} = \@maxAceArr;
}

#############################################
# Evaluate the Scaled WL and print metrics
#############################################
sub print_metrics {
  my ($aux_file, $ref_MetricsDB) = @_;
  my ($pwc, $sum, $rc, $Scaled_WL);
  my @maxAceArr = @{$ref_MetricsDB->{ACE_MAX}};
  
  my ($design, $dir, $ext) = fileparse($aux_file, '\..*');
  print "\n===== Quality Metrics ($design) =====\n";
  
  # Peak Weighted Congestion
  $pwc = $sum = 0.0;
  for(my $i=0; $i<@ACE_PERCENT_ARRAY; $i++)
  {
    $pwc += ($CONGESTION_WEIGHT[$i] * $maxAceArr[$i]);
    $sum += $CONGESTION_WEIGHT[$i];
  }
  $pwc = (100.0*$pwc)/$sum;
  
  # Routing Congestion
  $rc = max(100.0, $pwc);
  
  # Scaled Wire Length
  $Scaled_WL = $ref_MetricsDB->{HPWL}*(1.0 + $PENALTY_FACTOR*($rc - 100.0));
  
  print "Total Half Perimeter Wire Length: $ref_MetricsDB->{HPWL}\n";
  
  print "ACE      ";
  printf(" %.2lf%%   ", $_) foreach (@ACE_PERCENT_ARRAY);
  print "\n";
  print "         ";
  printf("%.2lf   ", 100*$_) foreach(@maxAceArr);
  print "\n";
  
  printf("Scaled Wire Length: %.0lf\n", $Scaled_WL);
}

############################################################
# generate congestion maps for each layer in gnuplot format
############################################################
sub plot_congestion_maps {
  my ($aux_file, $ref_RouteDB, $ref_TileCapacityDB, $ref_TileDemandDB) = @_;
  my ($x, $y, $z, $x_size, $y_size, @max_v, @max_h);
  
  print "\nGenerate congestion maps for each layer in gnuplot format...\n"
  if($VERBOSE);
  
  my $grid_x = $ref_RouteDB->{grid_x};
  my $grid_y = $ref_RouteDB->{grid_y};
  my $grid_z = $ref_RouteDB->{num_layers};
  my $tile_size_x = $ref_RouteDB->{tile_size_x};
  my $tile_size_y = $ref_RouteDB->{tile_size_y};
  my @v_capacity = @{$ref_RouteDB->{v_capacity}};
  my @h_capacity = @{$ref_RouteDB->{h_capacity}};
  my @wire_width = @{$ref_RouteDB->{wire_width}};
  my @wire_spacing = @{$ref_RouteDB->{wire_spacing}};
  my $core_width  = $grid_x * $tile_size_x;
  my $core_height = $grid_y * $tile_size_y;
  if($core_width > $core_height) {
    $x_size = 1000;
    $y_size = ($x_size*$core_height)/$core_width;
  } else {
    $y_size = 1000;
    $x_size = ($y_size*$core_width)/$core_height;
  }
  $x_size += 50;
  
  my ($design, $dir, $ext) = fileparse($aux_file, '\..*');
  
  # initialize max layer plots
  for $x (0 .. ($grid_x-1))
  {
    for $y (0 .. ($grid_y-1))
    {
      $max_v[$x][$y] = 0;
      $max_h[$x][$y] = 0;
    }
  }
  
  # generate layer-by-layer congestion maps
  for $z (0 .. ($grid_z-1))
  {
    next if(($h_capacity[$z] <= 0) && ($v_capacity[$z] <= 0));
    
    # layer stack: H,V,H,V....
    my $layer_id = $z + 1;
    my $file_name = "$design.M$layer_id.congestion.plt";
    open(OUTFILE, ">$file_name") or die "Can't open file: ($!)\n";
    
    print OUTFILE "set pm3d map corners2color c1\n";
    print OUTFILE "set cbrange [0:115]\n";
    print OUTFILE "unset key\n";
    print OUTFILE "unset xtics\n";
    print OUTFILE "unset ytics\n";
    print OUTFILE "set cbtics 0, 10, 115\n";
    #print OUTFILE "set palette rgbformulae 33,13,10\n";
    print OUTFILE "set palette defined (0 \"blue\", 10 \"cyan\", 30 \"green\", 45 \"yellow\", 70 \"orange\", 100 \"red\")\n";
#    print OUTFILE "set palette defined ( ";
#    print OUTFILE "0  \"navy\", 10 \"navy\", 20 \"navy\", ";
#    print OUTFILE "30 \"navy\", 40 \"navy\", 50 \"navy\", ";
#    print OUTFILE "60 \"navy\", 65 \"navy\", 70 \"forest-green\", ";
#    print OUTFILE "75 \"green\", 80 \"dark-yellow\", 85 \"yellow\", ";
#    print OUTFILE "90 \"gold\", 95 \"orange\", 100 \"red\", ";
#    print OUTFILE "105 \"dark-pink\", 110 \"light-magenta\", ";
#    print OUTFILE "115 \"purple\" )\n";
#
    print OUTFILE "set terminal png crop truecolor size $x_size, $y_size enhanced font ',16'\n";
    print OUTFILE "set style line 11 lc rgb '#101010' lt 1 lw 1.5\n";
    print OUTFILE "set border 4095 back ls 11 lw 3\n";

    print OUTFILE "set output \"$design.M$layer_id.congestion.png\"\n";
    print OUTFILE "splot [-1:$grid_x][-1:$grid_y] \'-\' matrix\n";
    
    if($h_capacity[$z] > 0)
    {
      # Horizontal layer
      for $y (0 .. ($grid_y-1))
      {
        for $x (0 .. ($grid_x-1))
        {
          my $c1 = ${$ref_TileCapacityDB->{L}}[$x][$y][$z];
          my $c2 = ${$ref_TileCapacityDB->{R}}[$x][$y][$z];
          my $d1 = ${$ref_TileDemandDB->{L}}[$x][$y][$z];
          my $d2 = ${$ref_TileDemandDB->{R}}[$x][$y][$z];
          my $b1 = $h_capacity[$z] - $c1;
          my $b2 = $h_capacity[$z] - $c2;
          my $p1 = 0;
          my $p2 = 0;
          if(($z == 1) || ($z == 2))
          {
            if($b1 < $IGNORE_EDGE_RATIO * $h_capacity[$z])
            {
              $p1 =  ceil(${$ref_RouteDB->{tile_pins}}[$x][$y] * $PIN_BLOCKAGE_FACTOR);
              $p1 += ceil(${$ref_RouteDB->{tile_pins}}[$x-1][$y] * $PIN_BLOCKAGE_FACTOR) if($x > 0);
              $p1 *= ($wire_width[$z] + $wire_spacing[$z]);
            }
            if($b2 < $IGNORE_EDGE_RATIO * $h_capacity[$z])
            {
              $p2 =  ceil(${$ref_RouteDB->{tile_pins}}[$x][$y] * $PIN_BLOCKAGE_FACTOR);
              $p2 += ceil(${$ref_RouteDB->{tile_pins}}[$x+1][$y] * $PIN_BLOCKAGE_FACTOR) if($x < $grid_x-1);
              $p2 *= ($wire_width[$z] + $wire_spacing[$z]);
            }
          }
          # cong = (demand + blockage) / max_capacity
          my $o1 = ($d1+$b1+$p1) / $h_capacity[$z];
          my $o2 = ($d2+$b2+$p2) / $h_capacity[$z];
          my $tile_cong = 100*max($o1, $o2);
          $max_h[$x][$y] = max($max_h[$x][$y], $tile_cong);
          print OUTFILE "$tile_cong ";
        }
        print OUTFILE "\n";
      }
    }
    else
    {
      # Vertical layer
      for $y (0 .. ($grid_y-1))
      {
        for $x (0 .. ($grid_x-1))
        {
          my $c1 = ${$ref_TileCapacityDB->{B}}[$x][$y][$z];
          my $c2 = ${$ref_TileCapacityDB->{T}}[$x][$y][$z];
          my $d1 = ${$ref_TileDemandDB->{B}}[$x][$y][$z];
          my $d2 = ${$ref_TileDemandDB->{T}}[$x][$y][$z];
          my $b1 = $v_capacity[$z] - $c1;
          my $b2 = $v_capacity[$z] - $c2;
          my $p1 = 0;
          my $p2 = 0;
          if(($z == 1) || ($z == 2))
          {
            if($b1 < $IGNORE_EDGE_RATIO * $v_capacity[$z])
            {
              $p1 =  ceil(${$ref_RouteDB->{tile_pins}}[$x][$y] * $PIN_BLOCKAGE_FACTOR);
              $p1 += ceil(${$ref_RouteDB->{tile_pins}}[$x][$y-1] * $PIN_BLOCKAGE_FACTOR) if($y > 0);
              $p1 *= ($wire_width[$z] + $wire_spacing[$z]);
            }
            if($b2 < $IGNORE_EDGE_RATIO * $v_capacity[$z])
            {
              $p2  = ceil(${$ref_RouteDB->{tile_pins}}[$x][$y] * $PIN_BLOCKAGE_FACTOR);
              $p2 += ceil(${$ref_RouteDB->{tile_pins}}[$x][$y+1] * $PIN_BLOCKAGE_FACTOR) if($y < $grid_y-1);
              $p2 *= ($wire_width[$z] + $wire_spacing[$z]);
            }
          }
          # cong = (demand + blockage) / max_capacity
          my $o1 = ($d1+$b1+$p1) / $v_capacity[$z];
          my $o2 = ($d2+$b2+$p2) / $v_capacity[$z];
          my $tile_cong = 100*max($o1, $o2);
          $max_v[$x][$y] = max($max_v[$x][$y], $tile_cong);
          print OUTFILE "$tile_cong ";
        }
        print OUTFILE "\n";
      }
    }
    
    close(OUTFILE);
  }
  
  # generate max vertical and horizontal congestion maps
  for $z (0 .. 1)
  {
    my $file_name;
    if($z == 0) {
      $file_name = "$design.Max_H.congestion.plt";
    } else {
      $file_name = "$design.Max_V.congestion.plt";
    }
    
    open(OUTFILE, ">$file_name") or die "Can't open file: ($!)\n";
    
    print OUTFILE "set pm3d map corners2color c1\n";
    print OUTFILE "set cbrange [0:115]\n";
    print OUTFILE "unset key\n";
    print OUTFILE "unset xtics\n";
    print OUTFILE "unset ytics\n";
    print OUTFILE "set cbtics 0, 10, 115\n";
    #print OUTFILE "set palette rgbformulae 33,13,10\n";
    print OUTFILE "set palette defined (0 \"blue\", 10 \"cyan\", 30 \"green\", 45 \"yellow\", 70 \"orange\", 100 \"red\")\n";
#    print OUTFILE "set palette defined ( ";
#    print OUTFILE "0  \"navy\", 10 \"navy\", 20 \"navy\", ";
#    print OUTFILE "30 \"navy\", 40 \"navy\", 50 \"navy\", ";
#    print OUTFILE "60 \"navy\", 65 \"navy\", 70 \"forest-green\", ";
#    print OUTFILE "75 \"green\", 80 \"dark-yellow\", 85 \"yellow\", ";
#    print OUTFILE "90 \"gold\", 95 \"orange\", 100 \"red\", ";
#    print OUTFILE "105 \"dark-pink\", 110 \"light-magenta\", ";
#    print OUTFILE "115 \"purple\" )\n";
#
    print OUTFILE "set terminal png crop truecolor size $x_size, $y_size enhanced font ',16'\n";
    print OUTFILE "set style line 11 lc rgb '#101010' lt 1 lw 1.5\n";
    print OUTFILE "set border 4095 back ls 11 lw 3\n";

    if($z == 0) {
      print OUTFILE "set output \"$design.Max_H.congestion.png\"\n";
    } else {
      print OUTFILE "set output \"$design.Max_V.congestion.png\"\n";
    }
    print OUTFILE "splot [-1:$grid_x][-1:$grid_y] \'-\' matrix\n";
    
    for $y (0 .. ($grid_y-1))
    {
      for $x (0 .. ($grid_x-1))
      {
        if($z == 0)
        {
          print OUTFILE "$max_h[$x][$y] ";
        }
        else
        {
          print OUTFILE "$max_v[$x][$y] ";
        }
      }
      print OUTFILE "\n";
    }
    
    close(OUTFILE);
  }
}


##################################################
sub process_line {
  my $line = $_[0];
  chomp $line;
  $line =~ s/^\s+//;
  $line =~ s/\s+$//;
  return $line;
}

sub min {
  if($_[0] < $_[1])
  {
    return $_[0];
  }
  else
  {
    return $_[1];
  }
}

sub max {
  if($_[0] > $_[1])
  {
    return $_[0];
  }
  else
  {
    return $_[1];
  }
}

sub round_up_int {
  my $arg = $_[0];
  $arg += 0.5;
  return int($arg);
}

sub sort_ascending {
  my @a_fields = split/:+/, $a;
  my @b_fields = split/:+/, $b;
  $a_fields[0] <=> $b_fields[0];
}

sub a_mean {
  return if(scalar(@_) <= 0);
  my $sum = 0.0;
  foreach my $val (@_)
  {
    $sum += $val;
  }
  return $sum/scalar(@_);
}

##################################################
sub calc_overflow_stats {
  my ($aux_file, $ref_RouteDB, $ref_TileCapacityDB, $ref_TileDemandDB, $ref_NetRouteDB) = @_;
  
  my $grid_x = $ref_RouteDB->{grid_x};
  my $grid_y = $ref_RouteDB->{grid_y};
  my $grid_z = $ref_RouteDB->{num_layers};
  
  print "calculate overflow and tile-to-tile routed wire length\n" if($VERBOSE);
  
  # get total routed wire length
  my $total_routed_wl = 0;
  foreach my $net_name (sort(keys(%{$ref_NetRouteDB})))
  {
    my $net_length = 0;
    my @t = split/;/, $ref_NetRouteDB->{$net_name};
    for my $j (@t)
    {
      my @r = split/,/, $j;
      my $x1 = $r[0];
      my $y1 = $r[1];
      my $l1 = $r[2];
      my $x2 = $r[3];
      my $y2 = $r[4];
      my $l2 = $r[5];
      
      if($x1 < $x2)
      {
        $net_length += ($x2 - $x1);
      }
      elsif($y1 < $y2)
      {
        $net_length += ($y2 - $y1);
      }
      elsif($l1 < $l2)
      {
        $net_length += $VIA_COST * ($l2 - $l1);
      }
      else
      {
        die "Inconsistent data for Net($net_name).\n";
      }
    }
    
    $total_routed_wl += $net_length;
  }
  
  # get congestion statistics
  my ($x, $y, $z);
  my $num_overflow_edges = 0;
  my $total_overflow = 0;
  my $max_overflow = 0;
  for $z (0 .. ($grid_z-1))
  {
    for $y (0 .. ($grid_y-1))
    {
      for $x (0 .. ($grid_x-1))
      {
        # Horizontal routes
        if(${$ref_TileDemandDB->{R}}[$x][$y][$z] > 
           ${$ref_TileCapacityDB->{R}}[$x][$y][$z])
        {
          my $overflow = (${$ref_TileDemandDB->{R}}[$x][$y][$z] - 
                          ${$ref_TileCapacityDB->{R}}[$x][$y][$z]);
          
          $num_overflow_edges++;
          $total_overflow += $overflow;
          $max_overflow = $overflow if($max_overflow < $overflow);
        }
        # Vertical routes
        if(${$ref_TileDemandDB->{B}}[$x][$y][$z] > 
           ${$ref_TileCapacityDB->{B}}[$x][$y][$z])
        {
          my $overflow = (${$ref_TileDemandDB->{B}}[$x][$y][$z] - 
                          ${$ref_TileCapacityDB->{B}}[$x][$y][$z]);
          
          $num_overflow_edges++;
          $total_overflow += $overflow;
          $max_overflow = $overflow if($max_overflow < $overflow);
        }
      }
    }
  }
  
  # print results
  my ($filename, $dir, $ext) = fileparse($aux_file, '\..*');
  printf("%-15s%15s%15s%15s\n", "Design", "TOT_OF", "MAX_OF", "WL");
  printf("%-15s%15d%15d%15d\n", $filename, $total_overflow, 
         $max_overflow, $total_routed_wl);
}

