#!/bin/bash

# Benchmarks
bench_suite=(
    "cordic2_ispd"
)

# Logic Synthesis
synth_scenarios=(
    "compress2rs"
)
max_fanout=16

# Floorplanning
utilization=0.5

# Placement
placers=(
    "ComPLx"
    "NTUPlace3"
    "FastPlaceGP"
    "mPL6"
)
target_density=0.75

# Timer
timers=(
    "iTimerC2.0"
)

# Gate Sizing
run_gs=false
sizers=(
    "USizer2013"
)

# Global Routing
global_routers=(
    "NCTUgr"
)
tile_size=30
num_layer=4
adjustment=10
safety=90

