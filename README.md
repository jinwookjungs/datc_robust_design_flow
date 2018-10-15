# DATC Robust Design Flow

## Notes
**Last updated**: Mon Oct 15 14:48:42 KST 2018

This repository is currently **under construction**.
Also, we are currently **not** providing the individual point tool binaries.

## Introduction
In recent years, there has been a slew of design automation contests and 
released benchmarks. Past examples include ISPD place & route contests, DAC 
placement contests, timing analysis contests at TAU, and CAD contests at ICCAD. 
Additional contests are planned for upcoming conferences. These are interesting 
and important events that stimulate the research of the target problems and 
advance the cutting edge technologies. Nevertheless, most contests focus only 
on the point tool problems and fail in addressing the design flow or 
co-optimization among design tools. OpenDesign Flow Database platform is 
developed to direct attention to the overall design flow from logic design to 
physical synthesis to manufacturability optimization. The goals are to provide:
1. An academic reference design flow based on past CAD contest results, 
2. The database for design benchmarks and point tool libraries
3. Standard design input/output formats to build a customized design flow by 
composing point tool libraries.


## Getting Started
OpenDesign Flow Database consists of the following directory structure:

    Flow configuration:   ./000_config
    Logic synthesis:      ./100_logic_synthesis
                          ./110_remove_dangling_nets
    Floorplanning:        ./200_floorplanning
                          ./210_create_def
    Placement:            ./300_placement
    Timing measurement:   ./310_write_def
                          ./320_timing
    Gate sizing:          ./400_gate_sizing
                          ./410_write_bookshelf
                          ./420_legalization
                          ./430_write_def
                          ./440_timing
    Global routing:       ./500_gr_bench_gen
                          ./510_global_route
    Detaile routing:      ./600_dr_benchmark_checker
                          ./610_detail_route
    Benchmarks            ./benchmarks
    Binaries              ./bin
    Utility scripts       ./utils

To give a first shot, please try runnning:
```
$ cd /path/to/your/workspace
$ git clone <this_repository>
$ cd datc_robust_design_flow
$ ./run.sh simple
```
which runs logic synthesis, placement, gate sizing, and global router with 
a simple test case.
The result of each stage can be found under the stage's directory, e.g.,
```
./100_logic_synthesis/synthesis
./200_floorplanning/bookshelf
./300_placement/placement
./400_gate_sizing/sizing
./510_global_route/global_route
./610_detail_route/detail_route
```

Every stage has the main run script (**`run_suite`**). The configuration of design flow
can be customized using the configuration script located at `000_config`. We can 
specify logic synthesis scenario, utilization of chip floorplan, placer, gate 
sizer, as well as global router. You can find an example flow configuration at:
```
./000_config/config_simple.sh
```

## Benchmarks
OpenDesign Flow Database 2017 has 26 benchmark circuits that are taken from  
[TAU Contest 2017](https://sites.google.com/site/taucontest2017/).
Since TAU Contest 2017 did not release complete Liberty library, we remapped
the benchmark circuits into our own technology library.
The standard cell library of OpenDesign Flow Database is based on the library of
ISPD'12/13 Gate Sizing Contest.
We took the LEF file from A2A methodology of UCSD (almost the same LEF file used
in ICCAD’15 TDP contest). Please refer to the paper for more details: 
> A. Kahng et al., “Horizontal Benchmark Extension for Improved Assessment of Physical CAD Research,” GLSVLSI’14

### Installing Benchmarks
Inside `benchmarks/utils` directory, theres’s a utility script named `install_tau17_benchmarks.py`.
Run it by:
```
$ python install_tau17_benchmarks.py
```
It will (1) download the benchmarks, (2) remap the benchmarks to the RDF cell library,
(3) remove the dangling wires, and (4) set up the benchmark directory.

**Notes**: The above python script only works with **python of version greater than 3**.
Also, it requires an additional module `requests`.
So, if you get an error `ModuleNotFoundError: No module named ‘requests’`, 
please install it, for example, by:
```
$ sudo pip install requests
```

## Flow configuration
You can configure the OpenDesign Flow Database with your preferred logic 
synthesis scenarios, placers, timers, and global routers.
An example flow configuration is shown below:
```shell
#!/bin/bash

# Benchmarks
bench_suite=(
    "cordic_ispd"
)

# Logic Synthesis
synth_scenarios=(
    "st"
)
max_fanout=16

# Floorplanning
utilization=0.5

# Placement
placers=(
    "EhPlacer"
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

# Detailed Routing
detail_routers=(
    "NCTUdr"
)
```

## Logic Synthesis
The **run_suite** script sets up and runs the synthesis expriments.  To launch a 
batch job on the full set of TAU benchmarks, the script is invoked as: 
```
run_suite all 
```

The script lists available benchmarks in the `bench_set` array. Similarly, 
possible synthesis "scenarios" are given in the `scenario_set` array. A user may 
fill-out the provided script variables `my_suite` and `my_scenarios` to run a 
customized experiment as: `run_suite my_suite`. 
(The `test_suite` and `test_scenario` variables in the script illustrate the 
customized setting.)

A `scenario` is currently defined by the ABC AIG optmization script,
int mapping command, and a Boolean indicating the use of timing
assertions (provided in the `<benchmark>.timing` file). The name aliases
for available ABC scripts and mapping commands are stored in the `./bin/abc.rc`
file.

The resulting verilog netlist gets stores in
```
synthesis/<benchmark>.<scenario>/<benchmark>.v"
```


## Bookshelf Generation

Bookshelf files are generated given the synthesis result. You can run this 
stage with **run_suite** script, similar to logic synthesis stage, after 
specifying the benchmarks and logic synthesis scenario in configuration file. 
The results will be stored at the directory named:
```
bookshelf/<benchmark>.<scenario>
```


## Placement
Currently, the following placer binaries are available:
- Eh?Placer
- Capo
- NTUPlace3
- ComPLx
- mPL5/6
- FastPlace3.0-GP

After placement, you can see the placement plot. The plot file will be stored at:
```
placement/<benchmark>.<scenario>.<placer>
```


## Timing Measurement
To measure the timing with ICCAD evaluation program, we need to generate 
the def files of placement results. It will be done by run_suite script
inside the "310_write_def" directory.

After def file geneartion, you can measure the timing with the ICCAD evaluation
program at "320_timing" directory. Currently, iTimerC2.0 and UI-Timer are
available. All the files dumped by the ICCAD evaluation prgram will be stored at:

```
timing/<benchmark>.<scenario>.<placer>/out
```


## Global Routing
You can generate the global routing benchmarks after placement, using the 
`run_batch` at `500_gr_bench_gen` directory.

After the benchmark generation, you can now run global routing at 
`510_globla_route`. Currently, `NCTUgr`, `FastRoute`, and `BFG-R` are available 
for global routing. After global routing, you can see the congestion map:

```
global_route/<benchmark>.<scenario>.<placer>.<router>/<benchmark>.Max_H.congestion.png
global_route/<benchmark>.<scenario>.<placer>.<router>/<benchmark>.Max_V.congestion.png
```

## Detail Routing
In RDF, global routing and detailed routing read input files based on ISPD 2008 Global Routing Contest and ISPD 2018 Initial Detailed Routing Contest, respectively. 
Since there is no industrial standard format for connecting global routing and detailed routing, we develop a global routing guide translator to translate the output format of ISPD 2008 Global Routing Contest into the input format of routing guide used in ISPD 2018 Initial Detailed Routing Contest. 
In ISPD 2018 Contest, a group of design rules and routing preference metrics are defined and stored in LEF/DEF files. 
As in commercial routers, the output of a detailed router follows DEF format that can be read by any commercial layout tools.

Currently, `NCTUdr` is included, and more tools from winning teams will be included.

## Gate Sizing Flow
To turn on the gate sizing flow, you need to set the **`run_gs`** flag in your 
flow configuration file. Note that the gate sizing takes very long time to run.
It can also be executed by run_suite scripts, inside the following directories:

    ./400_gate_sizing
    ./410_write_bookshelf
    ./420_legalization
    ./430_write_def
    ./440_timing


## References
* Jinwook Jung, Iris Hui-Ru Jiang, Gi-Joon Nam, Victor N. Kravets, Laleh Behjat, and Yin-Lang Li, "OpenDesign flow database: the infrastructure for VLSI design and design automation research," in Proceedings of the 35th International Conference on Computer-Aided Design (ICCAD '16). (DOI: https://doi.org/10.1145/2966986.2980074)
* Jinwook Jung, Iris Hui-Ru Jiang, Jianli Chen, Shih-Ting Lin, Yih-Lang Li, Victor N. Kravets, and Gi-Joon Nam, "DATC RDF: An Open Design Flow from Logic Synthesis to Detailed Routing," in Proceedings of 2018 Workshop on Open-Source EDA Technology ([Link to arxiv.org](https://arxiv.org/abs/1810.01078)).


## Authors
* Iris Hui-Ru Jiang - National Taiwan University
* Jianli Chen - Fuzhou University
* [Jinwook Jung](mailto:jinwookjungs@gmail.com) - [KAIST](http://dtlab.kaist.ac.kr)
* Victor N. Kravets - IBM Thomas J. Watson Research Center
* Shih-Ting Lin - National Chiao Tung University
* Yih-Lang Li - National Chiao Tung University
* Gi-Joon Nam - IBM Thomas J. Watson Research Center

## Former Contributers
* Laleh Behjat - University of Calgary

