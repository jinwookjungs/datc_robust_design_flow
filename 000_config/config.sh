#!/bin/bash

# Benchmarks
bench_suite=(
    "cordic_ispd"
)

# Logic Synthesis
synth_scenarios=(
    "timing"
)
max_fanout=16

# Floorplanning
utilization=0.6

# Placement
placers=(
    "NTUPlace3"
)
target_density=0.8

# Gate Sizing
run_gs=true
sizers=(
    "USizer2013"
)

# Global Routing
global_routers=("NCTUgr")
tile_size=50
num_layer=4
adjustment=10
safety=90

