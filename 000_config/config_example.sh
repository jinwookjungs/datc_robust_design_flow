#!/bin/bash

# Benchmarks
bench_suite=(
    "cordic_ispd"
)

# Logic Synthesis
synth_scenarios=(
    "lazyman"
    "timing"
)
max_fanout=16

# Floorplanning
utilization=0.5

# Placement
placers=(
    "NTUPlace3"
    "ComPLx"
)
target_density=0.8

# Timer
timers=(
    "iTimerC2.0"
)

# Gate Sizing
run_gs=true
sizers=(
    "USizer2013"
)

# Global Routing
global_routers=(
    "NCTUgr"
)
tile_size=30
num_layer=6
adjustment=10
safety=90

