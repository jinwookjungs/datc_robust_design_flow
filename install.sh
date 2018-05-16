#!/bin/bash

ROOT_DIR=`pwd`
echo $ROOT_DIR

# Install TAU'17 benchmarks
cd benchmarks/utils
python install_tau17_benchmarks.py --remove_unnecessary_files
#python install_tau17_benchmarks.py
cd $ROOT_DIR

# Install ABC
cd bin/

