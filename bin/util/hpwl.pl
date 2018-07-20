#!/usr/bin/perl 

# Written by Gi-Joon Nam (gnam@us.ibm.com) on Jan 2005
# usage : hpwl.pl <nodefile> <init.pl> <solution.pl> <net>
# output: print out the half-perimeter WL on stdout

%ObjectDB;
%NetDB;

$f_node = $ARGV[0];
$f_pl   = $ARGV[1];
$f_sol  = $ARGV[2];
$f_net  = $ARGV[3];

if (!defined($f_node) || !defined($f_pl) || !defined($f_sol) || !defined($f_net)) {
    print "Usage: hpwl.pl <.nodes file> <init.pl> <solution.pl> <.net file>\n";
    exit(0);
}

open (NODEFILE, $f_node)  || die "I can't open node file $f_node\n";
open (PLFILE,   $f_pl)    || die "I can't open pl   file $f_pl\n";
open (SOLFILE,  $f_sol)   || die "I can't open sol  file $f_sol\n";
open (NETFILE,  $f_net)   || die "I can't open net  file $f_net\n";

$DXINDEX=0;
$DYINDEX=1;
$LOCXINDEX=2;
$LOCYINDEX=3;

#####################################################################
# Node file processing
# For each object, store dx, dy, lx and ly. lx and ly will be updated
#     when solution PL file is processed. 
#####################################################################
$num_obj = 0;
$num_terminal = 0;
$index_object=0;
while (defined($line = <NODEFILE>)) {
  my @tmpRecord;

  $line =~ s/^\s+//; # removes front/end white spaces
  $line =~ s/\s+$//;
  @words = split(/\s+/, $line);
  @words + 0;
  $num_words = scalar(@words);

  if ($words[0] eq "#" || $words[0] eq "UCLA" || $num_words < 1) {
      # skip comment, UCLA line or empty line
      next;
  }
  if ($words[0] eq "NumNodes") {
      $num_obj_from_file = $words[2];
      next;
  }
  if ($words[0] eq "NumTerminals") {
      $num_term_from_file = $words[2];
      print "NumNodes: $num_obj_from_file NumTerminals: $num_term_from_file\n";
      next;
  }

  $name     = $words[0];
  $dx       = $words[1];
  $dy       = $words[2];
  $movetype = $words[3];

  if (!defined($name)) {
      print "\tERROR: Undefined object name $name.\n";
      my_exit();
  }
  if (defined($ObjectDB{$name})) {
      $index = $ObjectDB{$name};
      print "\tERROR: Object $name is defined before.(index=$index).\n";
      my_exit();
  }
  @tmpRecord = ($dx, $dy, 0, 0);
  $ObjectDB{$name} = \@tmpRecord;
  if ($movetype eq "terminal") {
      $num_terminal++;
  }
  $num_obj++;
}
close(NODEFILE);
print "Phase 1: Node file processing is done.\n";
print "         Total $num_obj objects (terminal $num_terminal).\n";

#################################################################
# initial PL file processing
# For each object, update lx and ly particularly for terminals
#################################################################
$num_obj = 0;
$num_terminal = 0;
while (defined($line = <PLFILE>)) {
  my @tmpRecord;

  $line =~ s/^\s+//; # removes front/end white spaces
  $line =~ s/\s+$//;
  @words = split(/\s+/, $line);
  @words + 0;
  $num_words = scalar(@words);

  if ($words[0] eq "#" || $words[0] eq "UCLA" || $num_words < 1) {
      next;
  }

  $name     = $words[0];
  $x        = $words[1];
  $y        = $words[2];
  $rest1    = $words[3]; # :
  $rest2    = $words[4]; # N
  $movetype = $words[5]; # /FIXED

  if (!defined($name)) {
      print "\tERROR: Undefined object name $name.\n";
      my_exit();
  }
  if (!defined($ObjectDB{$name})) {
      print "\tERROR: Object $name is NOT defined in ObjectDB.\n";
      my_exit();
  }
  ${$ObjectDB{$name}}[$LOCXINDEX] = $x;
  ${$ObjectDB{$name}}[$LOCYINDEX] = $y;

  $num_obj++;
}
close(PLFILE);
print "Phase 2: Input PL file processing is done.\n";
print "         Total $num_obj objects\n";

########################################
# Solution PL file processing
# For each object, update lx and ly
########################################
$num_obj = 0;
$num_terminal = 0;
while (defined($line = <SOLFILE>)) {
  my @tmpRecord;

  $line =~ s/^\s+//; # removes front/end white spaces
  $line =~ s/\s+$//;
  @words = split(/\s+/, $line);
  @words + 0;
  $num_words = scalar(@words);

  if ($words[0] eq "#" || $words[0] eq "UCLA" || $num_words < 1) {
      next;
  }

  $name     = $words[0];
  $x        = $words[1];
  $y        = $words[2];
  $rest1    = $words[3]; # :
  $rest2    = $words[4]; # N
  $movetype = $words[5]; # /FIXED

  if (!defined($name)) {
      print "\tERROR: Undefined object name $name.\n";
      my_exit();
  }
  if (!defined($ObjectDB{$name})) {
      print "\tERROR: Object $name is NOT defined in ObjectDB.\n";
      my_exit();
  }
  if ($movetype eq "/FIXED") {
      $lx_from_file =   ${$ObjectDB{$name}}[$LOCXINDEX];
      $ly_from_file =   ${$ObjectDB{$name}}[$LOCYINDEX];
      if ($x != $lx_from_file || $y != $ly_from_file) {
	  print "\tERROR: Fixed block ($name) moved from ($lx_from_file, $ly_from_file) to ($x, $y)\n";
	  my_exit();
      }
  }
  else {
      # movable objects
      ${$ObjectDB{$name}}[$LOCXINDEX] = $x;
      ${$ObjectDB{$name}}[$LOCYINDEX] = $y;
  }

  $num_obj++;
}
close(SOLFILE);
print "Phase 3: Solution PL file processing is done.\n";
print "         Total $num_obj objects\n";

########################
# NET file processing
########################
$num_net = 0;
$num_pin = 0;
$index_net = 0;
$total_wl = 0;
while (defined($line = <NETFILE>)) {
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

  $NetDB{$this_net_name} = $index_net;
  $index_net++;
  
  $this_net_wl = 0;
  $this_net_lx = 100000000;
  $this_net_ly = 100000000;
  $this_net_hx = -1;
  $this_net_hy = -1;
  
  for ($i = 0; $i < $this_num_pin; $i++) {
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
  }
  $this_net_wl = (($this_net_hx - $this_net_lx) + ($this_net_hy - $this_net_ly));
  if ($this_net_wl < 0) {
      print "\tERROR: Net $this_net_name HPWL=$this_net_wl (negative wl)\n";
      my_exit();
  }
  $total_wl += $this_net_wl;
  $num_net++;
  #print "this_net: $this_net_wl\ttotal: $total_wl\n";
}
close(NETFILE);
print "Phase 3: Net file processing is done.\n";
print "         Total $num_net nets $num_pin pins.\n";
print "         Total HPWL: $total_wl ($f_sol)\n";

sub my_exit {
  print "Abnormal condition happened. Exit\n";
  exit(1);
}
