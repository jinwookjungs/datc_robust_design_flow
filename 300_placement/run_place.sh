#!/bin/bash

# Parameter check
contains() {
    for i in $1; do
        [[ $i = $2 ]] && return 1
    done
    return 0
}
if test "$#" -ne 5; then
    echo "Usage: ./run_place.sh <bench> <bookshelf_dir> <placer> <target_density> <out_dir>"
    echo "Available placers: [EhPlacer | ComPLx | NTUPlace3 | mPL6 | mPL5 | Capo | FastPlace-GP]"
    exit
elif contains "EhPlacer ComPLx NTUPlace3 mPL6 mPL5 Capo FastPlaceGP" $3 = 0; then
    echo "Available placers: [EhPlacer | ComPLx | NTUPlace3 | mPL6 | mPL5 | Capo | FastPlace-GP]"
    exit
fi

# For run time measurement 
START=$(date +%s)

bench=$1
bookshelf_dir=$2
placer=$3
target_util=$4
out_dir=$5

aux_file=${bookshelf_dir}/${bench}.aux

bin_dir="../bin"
log=${bench}.${placer}.log

echo "Creating output directory: $out_dir"
echo ""
if [ -d $out_dir ]; then
    rm -rf $out_dir
fi
mkdir -p $out_dir

#------------------------------------------------------------------------------
# EhPlacer
#------------------------------------------------------------------------------
if test "$placer" = "EhPlacer"; then
    cp ${bookshelf_dir}/* .
    cmd="${bin_dir}/EhPlacer-bookshelf -i ${bench}.aux -o ${bench}-EhPlacer_dp.pl -cpu 6"
    echo $cmd
    eval $cmd | tee ${log}

    rm -f PO*.dat
    rm -f ${bench}.aux ${bench}.nodes ${bench}.nets ${bench}.wts ${bench}.scl ${bench}.pl ${bench}.shapes

    mv ${bench}.fp.log.txt ${out_dir}/
    mv ${bench}.log.txt ${out_dir}/
    mv ${bench}-EhPlacer_dp.pl ${out_dir}/

    out_pl=${bench}-EhPlacer_dp.pl

#------------------------------------------------------------------------------
# Capo placer
#------------------------------------------------------------------------------
elif test "$placer" = "Capo"; then

    cmd="$bin_dir/MetaPl-Capo10.2-Lnx64.exe -faster -f $aux_file -save"
    echo $cmd
    eval $cmd | tee ${log}

    mv out.pl ${out_dir}/${bench}_Capo.pl

    out_pl=${bench}_Capo.pl

#------------------------------------------------------------------------------
# NTUPlace3
#------------------------------------------------------------------------------
elif test "$placer" = "NTUPlace3"; then

    cmd="${bin_dir}/ntuplace3 -aux $aux_file -util $target_util"
    echo $cmd
    eval $cmd | tee ${log}

    mv *.pl $out_dir
    mv *.plt $out_dir

    out_pl=${bench}.ntup.pl

#------------------------------------------------------------------------------
# ComPLx 
#------------------------------------------------------------------------------
elif test "$placer" = "ComPLx"; then

    cmd="${bin_dir}/ComPLx.exe -f ${bookshelf_dir}/${bench}.aux -ut ${target_util}"
    echo $cmd
    eval $cmd | tee ${log}

    # Detailed placement with FastPlace3.0
    cmd="${bin_dir}/FastPlace3.0_Linux64_DP -legalize -noFlipping -target_density ${target_util}"
    cmd="$cmd ${bookshelf_dir} ${bench}.aux"
    cmd="$cmd . ${bench}-ComPLx.pl"
    echo $cmd
    eval $cmd | tee --append ${log}

    mv ${bench}-ComPLx.pl ${out_dir}/
    mv ${bench}_FP_dp.pl ${out_dir}/

    out_pl=${bench}_FP_dp.pl


#------------------------------------------------------------------------------
# FastPlaceGP 
#------------------------------------------------------------------------------
elif test "$placer" = "FastPlaceGP"; then

    #./FastPlace3.0_Linux32_GP [options] <benchmark_dir> <aux_file> <output_dir>
    cmd="${bin_dir}/FastPlace3.0_Linux32_GP -target_density ${target_util}"
    cmd="$cmd ${bookshelf_dir} ${bench}.aux ."
    echo $cmd
    eval $cmd | tee ${log}

    # Detailed placement with FastPlace3.0
    cmd="${bin_dir}/FastPlace3.0_Linux64_DP -legalize -noFlipping -target_density ${target_util}"
    cmd="$cmd ${bookshelf_dir} ${bench}.aux"
    cmd="$cmd . ${bench}_FP_gp.pl"
    echo $cmd
    eval $cmd | tee --append ${log}

    mv ${bench}_FP_gp.pl ${out_dir}/
    mv ${bench}_FP_dp.pl ${out_dir}/

    out_pl=${bench}_FP_dp.pl


#------------------------------------------------------------------------------
# mPL6 
#------------------------------------------------------------------------------
elif test "$placer" = "mPL6"; then

	cp ${bookshelf_dir}/* .
	#cmd="${bin_dir}/mPL6 -d ${bench}.aux -cluster_ratio 0.1 -mvcycle 0 -mPL_DP 0"
	cmd="${bin_dir}/mPL6 -d ${bench}.aux -mPL_DP 0 -target_density ${target_util}"
    echo $cmd
    eval $cmd | tee ${log}
	rm -f ${bench}.aux ${bench}.nodes ${bench}.nets ${bench}.wts ${bench}.scl ${bench}.pl ${bench}.shapes

    # Detailed placement with FastPlace3.0
    cmd="${bin_dir}/FastPlace3.0_Linux64_DP -legalize -noFlipping -target_density ${target_util}"
    cmd="$cmd ${bookshelf_dir} ${bench}.aux"
    cmd="$cmd . ${bench}-mPL.pl"
    echo $cmd
    eval $cmd | tee --append ${log}

    # mv *mPL-gp.pl $out_dir
    mv *mPL.pl $out_dir
    mv ${bench}_FP_dp.pl ${out_dir}/
    
    out_pl=${bench}_FP_dp.pl

#------------------------------------------------------------------------------
# mPL5
#------------------------------------------------------------------------------
elif test "$placer" = "mPL5"; then

	cp ${bookshelf_dir}/* .
	cmd="${bin_dir}/mPL5 -d ${bench}.aux -mPL_DP 0 -target_density ${target_util}"
    echo $cmd
    eval $cmd | tee ${log}
	rm -f ${bench}.aux ${bench}.nodes ${bench}.nets ${bench}.wts ${bench}.scl ${bench}.pl ${bench}.shapes

    # Detailed placement with FastPlace3.0
    cmd="${bin_dir}/FastPlace3.0_Linux64_DP -legalize -noFlipping -target_density ${target_util}"
    cmd="$cmd -target_density ${target_util}"
    cmd="$cmd . ${bench}-mPL.pl"
    echo $cmd
    eval $cmd | tee --append ${log}

    mv *mPL.pl $out_dir
    mv ${bench}_FP_dp.pl ${out_dir}/

    out_pl=${bench}_FP_dp.pl
fi

END=$(date +%s)
RUN_TIME=$(( $END - $START ))
echo "" | tee --append $log
echo "Run time: $RUN_TIME" | tee --append $log
echo "" | tee --append $log
mv $log $out_dir


# Copy the placement solution
ln -s ${out_pl} ${out_dir}/${bench}.solution.pl
