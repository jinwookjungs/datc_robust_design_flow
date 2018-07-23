#!/bin/bash

# Benchmarks
bench_suite=(
    "ac97_ctrl"
    "aes_core" 
    "cordic2_ispd"
    "cordic_ispd"
    "crc32d16N"     
    "des_perf"
    "des_perf_ispd"
    "edit_dist2_ispd"
    "edit_dist_ispd"
    "fft_ispd" 
    "leon2_iccad"
    "leon3mp_iccad"
    "matrix_mult_ispd"
    "mgc_edit_dist_iccad"
    "mgc_matrix_mult_iccad"
    "netcard_iccad"
    "pci_bridge32"
    "systemcaes"
    "systemcdes"
    "tv80"
    "usb_funct"
    "usb_phy_ispd"
    "vga_lcd"
    "vga_lcd_iccad"
    "wb_dma"
)

# Logic Synthesis
synth_scenarios=(
    "st"
    "resyn"
    "resyn2"
    "resyn2.nf"
    "resyn3"
    "compress"
    "compress2"
    "resyn2rs"
    "compress2rs"
    "recadd3"
    "lazyman"
    "lazyman.a"
    "lazyman.nf"
    "timing"
)
max_fanout=16

# Floorplanning
utilization=0.5

# Placement
placers=(
    "EhPlacer"
    "ComPLx"
    "NTUPlace3"
    "FastPlaceGP"
    "mPL6"
    "mPL5"
    "Capo"
)
target_density=0.8

# Timer
timers=(
    "UITimer"
    "iTimerC2.0"
)

# Gate Sizing
run_gs=true
sizers=(
    "USizer2012"
    "USizer2013"
)

# Global Routing
routers=(
    "NCTUgr"
    "FastRoute"
    "BFG-R"
)
tile_size=50
num_layer=4
adjustment=10
safety=90


