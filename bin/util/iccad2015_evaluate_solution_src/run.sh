#!/bin/bash
bench_list=(
"b19"
"vga_lcd"
"leon2"
"leon3mp"
"mgc_edit_dist"
"mgc_matrix_mult"
"netcard"
)

script_list=(
"resyn"
"resyn2"
"resyn2a"
"resyn3"
"compress"
"compress2"
"resyn2rs"
"compress2rs"
)

bench_list=("b19")

# mkdir initial_placement
mkdir ComPLx_FP NTUPlace3 mPL6 Capo10.2

for bench in "${bench_list[@]}"
do

	for script in "${script_list[@]}"
	do
		base_name=${bench}_${script}

		# ComPLx-FP
		./iccad2015_evaluate_solution ICCAD14.parm \
				../../bench/${bench}.iccad2014 0.7 \
				../20_run_placement/ComPLx_FP/${base_name}_FP_dp.pl | tee ${base_name}_ComPLx-FP.log
		rm -f *.spef *.def *.tau2015 *.timing
		mv ${base_name}* ComPLx_FP	
		
		# NTUplace 3
		./iccad2015_evaluate_solution ICCAD14.parm \
				../../bench/${bench}.iccad2014 0.7 \
				../20_run_placement/NTUPlace3/${base_name}.ntup.pl | tee ${base_name}_NTUplace3.log
		rm -f *.spef *.def *.tau2015 *.timing
		mv ${base_name}* NTUPlace3 
		
		
		# mPL6
		./iccad2015_evaluate_solution ICCAD14.parm \
				../../bench/${bench}.iccad2014 0.7 \
				../20_run_placement/mPL6/${base_name}-mPL.pl | tee ${base_name}_mPL6.log
		rm -f *.spef *.def *.tau2015 *.timing
		mv ${base_name}* mPL6 
		
		
		# Capo
		./iccad2015_evaluate_solution ICCAD14.parm \
				../../bench/${bench}.iccad2014 0.7 \
				../20_run_placement/Capo10.2/${base_name}_Capo.pl | tee ${base_name}_Capo.log
		rm -f *.spef *.def *.tau2015 *.timing
		mv ${base_name}* Capo10.2
		
	done
done
