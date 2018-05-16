#!/bin/bash

# Parameter check
contains() {
    for i in $1; do
        [[ $i = $2 ]] && return 1
    done
    return 0
}
if test "$#" -ne 6; then
    echo "Usage: ./run_sizer.sh <verilog> <sdc> <spef> <lib> <sizer>"
    echo "Available sizers: [USizer]"
    exit
elif contains "USizer2012 USizer2013" $5 = 0; then
    echo "Available sizers: [USizer]"
    exit
fi

verilog=$1
sdc=$2
spef=$3
lib=$4
sizer=$5

# For run time measurement 
START=$(date +%s)

#------------------------------------------------------------------------------
# UFRGS Sizer
#------------------------------------------------------------------------------
if test "$sizer" = "USizer2013"; then
    # write config file
    config_file=usizer.config
    echo "$verilog $sdc $spef $lib" > $config_file

    cmd="../bin/usizer2013 -config ${config_file} open-eda"
    echo $cmd; $cmd
fi
if test "$sizer" = "USizer2012"; then
    # write config file
    config_file=usizer.config
    echo "$verilog $sdc $spef $lib" > $config_file

    cmd="../bin/usizer2012 -config ${config_file} open-eda"
    echo $cmd; $cmd
fi


END=$(date +%s)
RUN_TIME=$(( $END - $START ))
echo ""
echo "Run time: $RUN_TIME" | tee --append $log
echo ""
