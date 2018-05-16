#!/bin/bash

if test "$#" -ne 8; then
    echo "$0: error - wrong number of arguments : $# instead of 8"
    echo "usage: $0 <benchmark name> <latch name> <clock signal> <max_fanout>\ "
    echo "                              <scenario> <abc script name> <abc map command> \ "
    echo "                              <true/false for using timing assrtions> \ "
    echo "                              <max_fanout>"
    exit
fi

bench=${1}
latch=$2
clk_src=$3
runid=$4
abc_script=$5
map=$6
timing=$7
max_fanout=$8

bench_dir="../benchmarks"
abc_bin="../bin/abc"
abc_rc="../bin/abc.rc"

bench_verilog=${bench_dir}/${bench}/${bench}.v
bench_lib=${bench_dir}/${bench}/${bench}_Late.lib
bench_blif=./rundata/${bench}_${runid}.blif
abc_input_blif=./rundata/${bench}_${runid}.input.blif
abc_verilog=./rundata/${bench}_${runid}.v
final="./synthesis/${bench}.${runid}"

final_verilog=${final}/${bench}.v



#-----------------------------------------------------------------------------
echo Output will be save in $final_verilog

echo "***********************************************"
echo "ABC scenario : \"$abc_script $map\""
echo ""
echo "1. Verilog to blif conversion"
echo "------------------------------------------------------------------------------"

if [ "$timing" == "true" ] 
then
    gen_assertions=1
    timing_assertions=${bench_dir}/${bench}/${bench}.timing
    if [ -f $timing_assertions ]
    then
        echo timing assertions : $timing_assertions
        makeblif="python3 ../utils/100_verilog_to_blif.py -i $bench_verilog -t $timing_assertions -o $bench_blif"
    else
        echo unable to locate timing assertions file : $timing_assertions
    fi
else
    makeblif="python3 ../utils/100_verilog_to_blif.py -i $bench_verilog -o $bench_blif"
fi

echo $makeblif; $makeblif
cp $bench_blif $abc_input_blif

echo ""
echo "2. ABC design synthesis - $bench"
echo "------------------------------------------------------------------------------"

mkdir -p $final

$abc_bin -o $bench_blif -c "
source $abc_rc;
echo Reading library $bench_lib ***;
read $bench_lib;
echo Reading abstracted netlist $bench_blif ***;
read $bench_blif;
echo "print_stats"; print_stats;
echo "print_latch"; print_latch;
echo "print_gates"; print_gates;
echo "print_fanio"; print_fanio;
echo "print_delay"; print_delay;
unmap;
$abc_script;
$map;
cleanup;
echo -n "$map:$abc_script:"; print_stats;
echo Buffering ... ;
buffer -N $max_fanout -v;
echo -n "buffer:$abc_script:"; 
echo "print_stats"; print_stats;
echo "print_latch"; print_latch;
echo "print_gates"; print_gates;
echo "print_fanio"; print_fanio;
echo "print_delay"; print_delay;
echo Saving out $abc_verilog ***;
write_verilog $abc_verilog
"
#if [ -f $bench_blif ] ; then
#    rm $bench_blif
#fi

echo ""
echo "3. Latch mapping - $bench"
echo "------------------------------------------------------------------------------"
makeverilog="python3 ../utils/100_map_latches.py -i $abc_verilog --latch $latch --clock $clk_src"
makeverilog="$makeverilog -o $final_verilog"
echo $makeverilog; $makeverilog

#if [ -f $abc_verilog ] ; then
#    rm $abc_verilog
#fi

echo "------------------------------------------------------------------------------"
echo ""
echo ""
