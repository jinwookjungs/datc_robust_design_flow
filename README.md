# OpenDesign Flow Database 2017
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
    Benchmarks            ./benchmarks
    Binaries              ./bin
    Utility scripts       ./utils

To give a first shot, please try runnning:
```
./run.sh example
```
which runs logic synthesis, placement, gate sizing, and global router with 
the cordic_ispd design.
The result of each stage can be found under the stage's directory, like
```
./100_logic_synthesis/synthesis
./200_floorplanning/bookshelf
./300_placement/placement
./400_gate_sizing/sizing
./510_global_route/global_route
```

Every stage has the main run script (**run_suite**). The configuration of design flow
can be customized using the configuration script located at 000_config. We can 
specify logic synthesis scenario, utilization of chip floorplan, placer, gate 
sizer, as well as global router. You can find an example flow configuration at:
```
./000_config/config_example.sh
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
    "NTUPlace3"
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
```


## Logic Synthesis
The **run_suite** script sets up and runs the synthesis expriments.  To launch a 
batch job on the full set of TAU benchmarks, the script is invoked as: 
```
run_suite tau
```

The script lists available benchmarks in the bench_set array. Similarly, 
possible synthesis "scenarios" are given in the scenario_set array. A user may 
fill-out provided script variables my_suite and my_scenarios to run a customized 
experiment as: run_suite my. (The test_suite and test_scenario variables in the 
script illustrate the customized setting.)

A "scenario" is currently defined by the ABC AIG optmization script,
int mapping command, and a Boolean indicating the use of timing
assertions (provided in the <benchmark>.timing file). The name aliases
for available ABC scripts and mapping commands are stored in the ./bin/abc.rc 
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
"run_batch" at "500_gr_bench_gen" directory.

After the benchmark generation, you can now run global routing at 
"510_globla_route". Currently, "NCTUgr", "FastRoute", and "BFG-R" are available 
for global routing. After global routing, you can see the congestion map:

```
global_route/<benchmark>.<scenario>.<placer>.<router>/<benchmark>.Max_H.congestion.png
global_route/<benchmark>.<scenario>.<placer>.<router>/<benchmark>.Max_V.congestion.png
```


## Gate Sizing Flow
To turn on the gate sizing flow, you need to set the **run_gs** flag in your 
flow configuration file. Note that the gate sizing takes very long time to run.
It can also be executed by run_suite scripts, inside the following directories:
    
    ./400_gate_sizing
    ./410_write_bookshelf
    ./420_legalization
    ./430_write_def
    ./440_timing


## References
Jinwook Jung, Iris Hui-Ru Jiang, Gi-Joon Nam, Victor N. Kravets, Laleh Behjat, and Yin-Lang Li, 
"OpenDesign flow database: the infrastructure for VLSI design and design automation research," in Proceedings of the 35th International Conference on Computer-Aided Design (ICCAD '16). 
DOI: https://doi.org/10.1145/2966986.2980074


## Authors
* Iris Hui-Ru Jiang
* Gi-Joon Nam
* Victor N. Kravets
* Laleh Behjat
* Yi-Lang Li
* [Jinwook Jung](mailto:jinwookjungs@gmail.com) - [KAIST](http://dtlab.kaist.ac.kr)

