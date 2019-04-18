#!/bin/bash

# Benchmarks
bench_suite=(
    "simple"
)

# Logic Synthesis
synth_scenarios=(
    "resyn2"
)
max_fanout=16

# Floorplanning
utilization=0.05

# Placement
placers=(
    "EhPlacer"
)
target_density=0.2

# Timer
timers=(
    "UITimer"
    "iTimerC2.0"
)

# Gate Sizing
run_gs=false
sizers=(
    "USizer2013"
)

# Global Routing
global_routers=("NCTUgr")

tile_size=50
num_layer=4
adjustment=10
safety=90

# Detailed Routing
detail_routers=(
    "NCTUdr"
)

