#! /usr/bin/tclsh

if { $argc < 2 } {
    puts "Usage: $argv0 <.gr> <.nodes> (output: .route)"
    exit 0
}


set ifp1 [open [lindex $argv 0]]
set ifp2 [open [lindex $argv 1]]

regsub {\.nodes} [lindex $argv 1] "" design


set numb 0
set ofp [open ${design}.route "w"]

set start 0
set num 0
while { [gets $ifp1 line] >= 0 } {
    if { [regexp {^grid} $line] } {
        set grid [lrange $line 1 end]
        incr num

    }
    if { [regexp {^vertical capacity} $line] } {
        set vcap [lrange $line 2 end]
        incr num
    }
    if { [regexp {^horizontal capacity} $line] } {
        set hcap [lrange $line 2 end]
        incr num
    }
    if { [regexp {^minimum width} $line] } {
        set mw [lrange $line 2 end]
        incr num
    }
    if { [regexp {^minimum spacing} $line] } {
        set ms [lrange $line 2 end]
        incr num
    }
    if { [regexp {^via spacing} $line] } {
        set vs [lrange $line 2 end]
        set start 1
        incr num
        continue
    }
    if { $start } {
        set orig [lrange $line 0 1]
        set tsize [lrange $line 2 3]
        set start 0
    }
    if { $num == 7 } {
        break
    }
}

close $ifp1


set terms ""
while { [gets $ifp2 line] >= 0 } {
    if { [regexp {^NumTerminals} $line] } {
        set numT [lindex $line 2]
    }
    if { [lindex $line 3] == "terminal" || [lindex $line 3] == "terminal_NI"} {
        set terms "$terms [lindex $line 0]"
    }
}
close $ifp2

# write route file
puts $ofp "route 1.0"
puts $ofp "" 

puts $ofp "Grid               : $grid"
puts $ofp "VerticalCapacity   : $vcap"
puts $ofp "HorizontalCapacity : $hcap"
puts $ofp "MinWireWidth       : $mw"
puts $ofp "MinWireSpacing     : $ms"
puts $ofp "ViaSpacing         : $vs"
puts $ofp "GridOrigin         : $orig"
puts $ofp "TileSize           : $tsize"
puts $ofp "BlockagePorosity   : 0"

puts $ofp ""
puts $ofp "NumNiTerminals : $numT"
puts $ofp ""
foreach term $terms {
puts $ofp [format "%15s %6d"  $term "1"]
}
puts $ofp ""

puts $ofp "NumBlockageNodes : $numb"
close $ofp




