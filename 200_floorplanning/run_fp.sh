#!/bin/bash

if test "$#" -ne 5; then
    echo "Usage: ./run_new_fp.sh <bench> <netlist> <lef> <clock_port> <utilization>"
    exit
fi

bench=${1}
netlist=${2}
lef=${3}
clock_port=${4}
utilization=${5}

bench_dir="../bench"

echo "Netlist: ${netlist}"
echo "--------------------------------------------------------------------------------"
cmd="python3 ../utils/200_generate_bookshelf.py -i ${netlist}"
cmd="$cmd --lef $lef --clock ${clock_port} --util $utilization"
cmd="$cmd -o ${bench}"

echo $cmd; 
$cmd | tee ${bench}.fp.log.txt
echo ""


#echo "Restore terminal location"
#python3 merge_pl.py --nodes ${out_dir}/${base_name}.nodes --src ${out_dir}/${base_name}.pl	\
#                    --ref ${ref_bookshelf_path}/bookshelf-${bench}/${bench}.pl
#
#echo "Restore scl"
#cp ${ref_bookshelf_path}/bookshelf-${bench}/${bench}.scl ${out_dir}/${base_name}.scl
