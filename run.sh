suite=$1

echo "================================================================================"
echo " ___   _ _____ ___   ___ ___  ___ "
echo "|   \\ /_\\_   _/ __| | _ \\   \\| __|"
echo "| |) / _ \\| || (__  |   / |) | _| "
echo "|___/_/ \\_\\_| \\___| |_|_\\___/|_|  "

echo "================================================================================"

echo -e "\nLast updated: Mon Jul 23 11:37:24 KST 2018\n"

if [ -z "$suite" ]; then
    echo "(I) Suite is set to \"simple\"."
    suite="simple"
fi

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
`cd 600_dr_benchmark_checker; pwd -P`
`cd 610_detail_route; pwd -P`
)

for directory in "${directories[@]}"
do
    echo "Current directory: $directory"
    cd $directory
    make $suite
done

