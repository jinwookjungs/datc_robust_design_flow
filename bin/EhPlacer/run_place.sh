#!/bin/bash

# Parameter check
contains() {
    for i in $1; do
        [[ $i = $2 ]] && return 1
    done
    return 0
}
if test "$#" -ne 4; then
    echo "Usage: ./run_place.sh <bench> <bookshelf_dir> <placer> <out_dir>"
    echo "Available placers: [ComPLx | NTUPlace3 | mPL6 | mPL5 | Capo | Eh?Placer]"
    exit
elif contains "ComPLx NTUPlace3 mPL6 mPL5 Capo Eh?Placer" $3 = 0; then
    echo "Available placers: [ComPLx | NTUPlace3 | mPL6 | mPL5 | Capo | Eh?Placer]"
    exit
fi

# For run time measurement 
START=$(date +%s)

bench=$1
bookshelf_dir=$2
placer=$3
out_dir=$4

aux_file=${bookshelf_dir}/${bench}.aux

bin_dir="../bin"
log=${bench}_${placer}.log


#------------------------------------------------------------------------------
# Capo placer
#------------------------------------------------------------------------------
if test "$placer" = "Capo"; then

    cmd="$bin_dir/MetaPl-Capo10.2-Lnx64.exe -faster -f $aux_file -save"
    echo $cmd
    eval $cmd | tee ${log}

    if [ -d $out_dir ]; then
        rm -rf $out_dir
    fi
    mkdir $out_dir
    mv out.pl ${out_dir}/${bench}_Capo.pl

    out_pl=${bench}_Capo.pl

#------------------------------------------------------------------------------
# NTUPlace3
#------------------------------------------------------------------------------
elif test "$placer" = "NTUPlace3"; then

    cmd="${bin_dir}/ntuplace3 -aux $aux_file"
    echo $cmd
    eval $cmd | tee ${log}

    if [ -d $out_dir ]; then
        rm -rf $out_dir
    fi
    mkdir $out_dir
    mv *.pl $out_dir
    mv *.plt $out_dir

    out_pl=${bench}.ntup.pl

#------------------------------------------------------------------------------
# ComPLx 
#------------------------------------------------------------------------------
elif test "$placer" = "ComPLx"; then

    cmd="${bin_dir}/ComPLx.exe -f ${bookshelf_dir}/${bench}.aux"
    echo $cmd
    eval $cmd | tee ${log}

    # Detailed placement with FastPlace3.0
    cmd="${bin_dir}/FastPlace3.0_Linux64_DP -legalize -noFlipping ${bookshelf_dir} ${bench}.aux"
    cmd="$cmd . ${bench}-ComPLx.pl"
    echo $cmd
    eval $cmd | tee --append ${log}

    if [ -d $out_dir ]; then
        rm -rf $out_dir
    fi
    mkdir $out_dir
    mv ${bench}-ComPLx.pl ${out_dir}/
    mv ${bench}_FP_dp.pl ${out_dir}/

    out_pl=${bench}_FP_dp.pl

#------------------------------------------------------------------------------
# mPL6 
#------------------------------------------------------------------------------
elif test "$placer" = "mPL6"; then

	cp ${bookshelf_dir}/* .
	#cmd="${bin_dir}/mPL6 -d ${bench}.aux -cluster_ratio 0.1 -mvcycle 0 -mPL_DP 0"
	cmd="${bin_dir}/mPL6 -d ${bench}.aux -mPL_DP 0"
    echo $cmd
    eval $cmd | tee ${log}
	rm -f ${bench}.aux ${bench}.nodes ${bench}.nets ${bench}.wts ${bench}.scl ${bench}.pl ${bench}.shapes

    # Detailed placement with FastPlace3.0
    cmd="${bin_dir}/FastPlace3.0_Linux64_DP -legalize -noFlipping ${bookshelf_dir} ${bench}.aux"
    cmd="$cmd . ${bench}-mPL.pl"
    echo $cmd
    eval $cmd | tee --append ${log}

    if [ -d $out_dir ]; then
        rm -rf $out_dir
    fi
    mkdir $out_dir
    # mv *mPL-gp.pl $out_dir
    mv *mPL.pl $out_dir
    mv ${bench}_FP_dp.pl ${out_dir}/
    
    out_pl=${bench}_FP_dp.pl

#------------------------------------------------------------------------------
# mPL5
#------------------------------------------------------------------------------
elif test "$placer" = "mPL5"; then

	cp ${bookshelf_dir}/* .
	cmd="${bin_dir}/mPL5 -d ${bench}.aux -mPL_DP 0"
    echo $cmd
    eval $cmd | tee ${log}
	rm -f ${bench}.aux ${bench}.nodes ${bench}.nets ${bench}.wts ${bench}.scl ${bench}.pl ${bench}.shapes

    # Detailed placement with FastPlace3.0
    cmd="${bin_dir}/FastPlace3.0_Linux64_DP -legalize -noFlipping ${bookshelf_dir} ${bench}.aux"
    cmd="$cmd . ${bench}-mPL.pl"
    echo $cmd
    eval $cmd | tee --append ${log}

    if [ -d $out_dir ]; then
        rm -rf $out_dir
    fi
    mkdir $out_dir
    mv *mPL.pl $out_dir
    mv ${bench}_FP_dp.pl ${out_dir}/

    out_pl=${bench}_FP_dp.pl
#------------------------------------------------------------------------------
# Eh?Placer
#------------------------------------------------------------------------------
elif test "$placer" = "Eh?Placer"; then

	cp ${bookshelf_dir}/* .
	cmd="${bin_dir}/EhPlacer-bookshelf -i ${bench}.aux -o ${bench}-EhPlacer_dp.pl -cpu 6"
  echo $cmd
  eval $cmd | tee ${log}
	rm -f ${bench}.aux ${bench}.nodes ${bench}.nets ${bench}.wts ${bench}.scl ${bench}.pl ${bench}.shapes
  #No need to run FastPlace3.0 because Eh?Placer has a detailed placer inside
  mv ${bench}_EhPlacer_dp.pl ${out_dir}/

fi

END=$(date +%s)
RUN_TIME=$(( $END - $START ))
echo "" | tee --append $log
echo "Run time: $RUN_TIME" | tee --append $log
echo "" | tee --append $log
mv $log $out_dir


# Generate a placement plot
cmd="python3 ../utils/300_placement_plotter.py"
cmd="$cmd --nodes ${bookshelf_dir}/${bench}.nodes --scl ${bookshelf_dir}/${bench}.scl"
cmd="$cmd --pl ${out_dir}/${out_pl} --out out"
echo $cmd
eval $cmd
gnuplot out.plt
mv out.plt ${out_dir}/${out_dir}_plot.plt
mv out.png ${out_dir}/${out_dir}_plot.png

# Copy the placement solution
cp ${out_dir}/${out_pl} ${out_dir}/${bench}_solution.pl
