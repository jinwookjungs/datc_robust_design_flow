#!/bin/bash

# Parameter checks
contains() {
    for i in $1; do
        [[ $i = $2 ]] && return 1
    done
    return 0
}
if test "$#" -ne 5; then
    echo "Usage: ./run_droute.sh <lef> <def> <guide> <out_name>"
    echo "Available routers: [NCTUdr]"
    exit
elif contains "NCTUdr" $1 = 0; then
    echo "Available routers: [NCTUdr]"
    exit
fi

# For run time measurement 
START=$(date +%s)

router="$1"
lef=$2
def=$3
guide=$4
out_name=$5
log=${out_name}.log

bin_dir="../bin"


#------------------------------------------------------------------------------
# NCTUdr
#------------------------------------------------------------------------------
if test "$router" = "NCTUdr"; then
    mkdir flute-3.1
    ln -s ""$(cd ../bin; pwd -P)"/PORT9.dat" flute-3.1/
    ln -s ""$(cd ../bin; pwd -P)"/POST9.dat" flute-3.1/
    ln -s ""$(cd ../bin; pwd -P)"/POWV9.dat" flute-3.1/

    cmd="$bin_dir/NCTU-DR/NCTUdr -lef ${lef} -def ${def} -guide ${guide} -threads 8 -output ${out_name}"
    echo $cmd
    eval $cmd | tee $log

    rm -rf flute-3.1 Lef Def
fi


