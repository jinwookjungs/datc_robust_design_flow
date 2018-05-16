suite=$1

declare -a directories=(
`cd 100_logic_synthesis; pwd -P`
`cd 110_remove_dangling_nets; pwd -P`
`cd 200_floorplanning; pwd -P`
`cd 210_create_def; pwd -P`
`cd 300_placement; pwd -P`
`cd 310_write_def; pwd -P`
`cd 320_timing; pwd -P`
`cd 400_gate_sizing; pwd -P`
`cd 410_write_bookshelf; pwd -P`
`cd 420_legalization; pwd -P`
`cd 430_write_def; pwd -P`
`cd 440_timing; pwd -P`
`cd 500_gr_bench_gen; pwd -P`
`cd 510_global_route; pwd -P`
)

for directory in "${directories[@]}"
do
    echo $directory
    cd $directory
    make $suite
done

