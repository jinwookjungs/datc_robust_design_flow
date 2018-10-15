#!/bin/bash
# possible calls: run_suite [my_suite|simple|test|all]

suite=$1
echo $0: using $1 benchmark suite

case $suite in
    my_suite) source ../000_config/config.sh
    ;;
    simple)   source ../000_config/config_simple.sh
    ;;
    test)     source ../000_config/config_test.sh
    ;;
    all)      source ../000_config/config_all.sh
    ;;
    *)        source ../000_config/config_simple.sh
    ;;
esac

declare -a these_benches=("${bench_suite[@]}")
declare -a these_scenarios=("${synth_scenarios[@]}")
declare -a these_placers=("${placers[@]}")
declare -a these_timers=("${timers[@]}")
declare -a these_sizers=("${sizers[@]}")
declare -a these_grouters=("${global_routers[@]}")
declare -a these_drouters=("${detail_routers[@]}")

clock_name='clk'

# Create directories
mkdir -p ../100_logic_synthesis/reports 
mkdir -p ../100_logic_synthesis/rundata 
mkdir -p ../100_logic_synthesis/synthesis
mkdir -p ../110_remove_dangling_nets/verilog
mkdir -p ../200_floorplanning/bookshelf
mkdir -p ../210_create_def/def
mkdir -p ../300_placement/placement
mkdir -p ../310_write_def/def
mkdir -p ../320_timing/timing
mkdir -p ../400_gate_sizing/sizing
mkdir -p ../410_write_bookshelf/bookshelf
mkdir -p ../420_legalization/placement
mkdir -p ../430_write_def/def
mkdir -p ../440_timing/timing
mkdir -p ../500_gr_bench_gen/gr_bench
mkdir -p ../510_global_route/global_route
mkdir -p ../600_dr_benchmark_checker/lefdef
mkdir -p ../610_detail_route/detail_route

bench_dir=`cd ../benchmarks; pwd -P`
logic_synth_dir=`cd ../100_logic_synthesis/synthesis; pwd -P`
final_verilog_dir=`cd ../110_remove_dangling_nets/verilog; pwd -P`
floorplan_dir=`cd ../200_floorplanning/bookshelf; pwd -P`
initial_def_dir=`cd ../210_create_def/def; pwd -P`
placement_dir=`cd ../300_placement/placement; pwd -P`
write_def_dir=`cd ../310_write_def/def; pwd -P`
timing_dir=`cd ../320_timing/timing; pwd -P`
sizing_dir=`cd ../400_gate_sizing/sizing; pwd -P`
sizer_bookshelf_dir=`cd ../410_write_bookshelf/bookshelf; pwd -P`
sizer_legalization_dir=`cd ../420_legalization/placement; pwd -P`
sizer_def_dir=`cd ../430_write_def/def; pwd -P`
sizer_timing_dir=`cd ../440_timing/timing; pwd -P`
gr_bench_dir=`cd ../500_gr_bench_gen/gr_bench; pwd -P`
global_route_dir=`cd ../510_global_route/global_route; pwd -P`
dr_lefdef_dir=`cd ../600_dr_benchmark_checker/lefdef; pwd -P`
detail_route_dir=`cd ../610_detail_route/detail_route; pwd -P`

# Available Benchmarks
declare -A bench_set=(
#   [<bench-key>] = '<map-to-latch clock-signal>
    [ac97_ctrl]="ms00f20 clk"
    [aes_core]="ms00f20 clk" 
    [crc32d16N]="ms00f20 clk"     
    [des_perf]="ms00f20 clk"
    [leon2]="ms00f20 clk"
    [leon3mp]="ms00f20 clk"
    [mgc_edit_dist]="ms00f20 clk"
    [mgc_matrix_mult]="ms00f20 clk"
    [netcard]="ms00f20 clk"
    [pci_bridge32]="ms00f20 clk"
    [simple_release]="ms00f20 clk"
    [systemcaes]="ms00f20 clk"
    [systemcdes]="ms00f20 clk"
    [tv80]="ms00f20 clk"
    [usb_funct]="ms00f20 clk"
    [vga_lcd]="ms00f20 clk"
    [wb_dma]="ms00f20 clk"
    [cordic2_ispd]="ms00f20 clk"
    [cordic_ispd]="ms00f20 clk"
    [des_perf_ispd]="ms00f20 clk"
    [edit_dist2_ispd]="ms00f20 clk"
    [edit_dist_ispd]="ms00f20 clk"
    [fft_ispd]="ms00f20 clk" 
    [matrix_mult_ispd]="ms00f20 clk"
    [usb_phy_ispd]="ms00f20 clk"
    [b19_iccad]="ms00f20 clk"
    [leon2_iccad]="ms00f20 clk"
    [leon3mp_iccad]="ms00f20 clk"
    [mgc_edit_dist_iccad]="ms00f20 clk"
    [mgc_matrix_mult_iccad]="ms00f20 clk"
    [netcard_iccad]="ms00f20 clk"
    [vga_lcd_iccad]="ms00f20 clk"
    [simple]="ms00f20 clk"
)

# Logic Synthesis Scenarios
declare -A scenario_set=(
#   [<scenario-key>] = '<script-name map-command use-timing>
    [st]='st map false'
    [resyn]='resyn map false'
    [resyn2]='resyn2 map false'
    [resyn2.nf]='resyn2 nfmap false'
    [resyn3]='resyn3 map false'
    [compress]='compress map false'
    [compress2]='compress2 map false'
    [resyn2rs]='resyn2rs map false'
    [compress2rs]='compress2rs map false'
    [recadd3]='recadd3 map false'
    [lazyman]='lazyman map false'
    [lazyman.a]='lazyman amap false'
    [lazyman.nf]='lazyman nfmap false'
    [timing]='timing map true'
)

# Placers
declare -a placer_set=(
    "EhPlacer"
    "ComPLx"
    "NTUPlace3"
    "FastPlaceGP"
    "mPL6"
    "mPL5"
    "Capo"
)

# Timers
declare -a timer_set=(
    "UITimer"
    "iTimerC2.0"
    "OpenTimer"
)


# Sizers
declare -a sizer_set=(
    "USizer2012"
    "USizer2013"
)

# Global Routers
declare -a grouter_set=(
    "NCTUgr"
    "FastRoute"
    "BFG-R"
)

# Detail Routers
declare -a drouter_set=(
    "NCTUdr"
)

# Checking...
for benchkey in "${these_benches[@]}"
do
    grep -qwe "$benchkey" <(echo "${!bench_set[@]}")
    if [ $? -eq 1 ]; then
        echo "Error: benchmark $benchkey does not exist"
        exit 1
    fi
done

for scenkey in "${these_scenarios[@]}"
do
    grep -qwe "$scenkey" <(echo "${!scenario_set[@]}")
    if [ $? -eq 1 ]; then
        echo "Error: scenario $scenkey does not exist"
        exit 2
    fi
done

for placer in "${these_placers[@]}"
do
    grep -qwe "$placer" <(echo "${placer_set[@]}")
    if [ $? -eq 1 ]; then
        echo "Error: placer $placer does not exist"
        exit 3
    fi
done

for timer in "${these_timers[@]}"
do
    grep -qwe "$timer" <(echo "${timer_set[@]}")
    if [ $? -eq 1 ]; then
        echo "Error: timer $timer does not exist"
        exit 4
    fi
done

for sizer in "${these_sizers[@]}"
do
    grep -qwe "$sizer" <(echo "${sizer_set[@]}")
    if [ $? -eq 1 ]; then
        echo "Error: sizer $sizer does not exist"
        exit 5
    fi
done

for grouter in "${these_grouters[@]}"
do
    grep -qwe "$grouter" <(echo "${grouter_set[@]}")
    if [ $? -eq 1 ]; then
        echo "Error: global router $grouter does not exist"
        exit 6
    fi
done

for drouter in "${these_drouters[@]}"
do
    grep -qwe "$drouter" <(echo "${drouter_set[@]}")
    if [ $? -eq 1 ]; then
        echo "Error: detailed router $drouter does not exist"
        exit 6
    fi
done

