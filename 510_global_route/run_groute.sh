#!/bin/bash

# Parameter checks
contains() {
    for i in $1; do
        [[ $i = $2 ]] && return 1
    done
    return 0
}
if test "$#" -ne 3; then
    echo "Usage: ./run_groute.sh <input_gr> <router> <out_name>"
    echo "Available routers: [NCTUgr | FastRoute ]"
    exit
elif contains "NCTUgr FastRoute BFG-R" $2 = 0; then
    echo "Available routers: [NCTUgr | FastRoute | BFG-R]"
    exit
fi

# For run time measurement 
START=$(date +%s)

input_gr=$1
router=$2
out_name=$3
log=${out_name}.log

bin_dir="../bin"

#------------------------------------------------------------------------------
# NCTUgr
#------------------------------------------------------------------------------
if test "$router" = "NCTUgr"; then
    cmd="$bin_dir/NCTUgr REGULAR_ISPD $input_gr ${bin_dir}/NCTUgr_RegularHighQuality.set $out_name"
    echo $cmd
    eval $cmd | tee $log

#------------------------------------------------------------------------------
# FastRoute
#------------------------------------------------------------------------------
elif test "$router" = "FastRoute"; then
    # It seems not to work when the binary is not in the current location
    ln -s ../bin/FastRoute
    cmd="./FastRoute $input_gr -o $out_name"
    echo $cmd
    eval $cmd | tee $log
    rm -f FastRoute

#------------------------------------------------------------------------------
# BFG-R
#------------------------------------------------------------------------------
elif test "$router" = "BFG-R"; then
    # It seems not to work when the binary is not in the current location
    cmd="$bin_dir/FGR $input_gr -o $out_name"
    echo $cmd
    eval $cmd | tee $log
fi

