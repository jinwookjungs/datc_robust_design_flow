#!/bin/bash

# Benchmarks
bench_suite=(
    "ac97_ctrl"
    "cordic2_ispd"
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
    "ComPLx"
    "NTUPlace3"
)
target_density=0.8

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
num_layer=8
adjustment=10
safety=90

# Detailed Routing
detail_routers=(
    "NCTUdr"
)

