# Synopsys Design Constraints Format
# Copyright ? 2011, Synopsys, Inc. and others. All Rights reserved.

# clock definition
create_clock -name clk -period 80.0 [get_ports clk]

# input delays
set_input_delay  0.0 [get_ports {inp1}] -clock clk
set_input_delay  0.0 [get_ports {inp2}] -clock clk

# input drivers
set_driving_cell -lib_cell in01f80 -pin o [get_ports {inp1}] -input_transition_fall 10.0 -input_transition_rise 10.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports {inp2}] -input_transition_fall 10.0 -input_transition_rise 10.0

# output delays
set_output_delay  0.0 [get_ports {out}] -clock clk

# output loads
set_load -pin_load  4.0 [get_ports {out}]
