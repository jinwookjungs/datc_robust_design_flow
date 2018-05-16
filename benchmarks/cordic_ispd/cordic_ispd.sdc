# Synopsys Design Constraints Format

# clock definition
create_clock -name clk -period 7200.0 [get_ports clk]

# input delays
set_input_delay 0.0 [get_ports beta_11] -clock clk
set_input_delay 0.0 [get_ports beta_24] -clock clk
set_input_delay 0.0 [get_ports beta_8] -clock clk
set_input_delay 0.0 [get_ports beta_5] -clock clk
set_input_delay 0.0 [get_ports beta_25] -clock clk
set_input_delay 0.0 [get_ports beta_22] -clock clk
set_input_delay 0.0 [get_ports beta_30] -clock clk
set_input_delay 0.0 [get_ports beta_6] -clock clk
set_input_delay 0.0 [get_ports beta_27] -clock clk
set_input_delay 0.0 [get_ports beta_3] -clock clk
set_input_delay 0.0 [get_ports beta_13] -clock clk
set_input_delay 0.0 [get_ports beta_29] -clock clk
set_input_delay 0.0 [get_ports beta_12] -clock clk
set_input_delay 0.0 [get_ports beta_15] -clock clk
set_input_delay 0.0 [get_ports beta_20] -clock clk
set_input_delay 0.0 [get_ports beta_21] -clock clk
set_input_delay 0.0 [get_ports beta_28] -clock clk
set_input_delay 0.0 [get_ports beta_1] -clock clk
set_input_delay 0.0 [get_ports beta_2] -clock clk
set_input_delay 0.0 [get_ports beta_9] -clock clk
set_input_delay 0.0 [get_ports beta_7] -clock clk
set_input_delay 0.0 [get_ports rst] -clock clk
set_input_delay 0.0 [get_ports beta_16] -clock clk
set_input_delay 0.0 [get_ports beta_18] -clock clk
set_input_delay 0.0 [get_ports beta_0] -clock clk
set_input_delay 0.0 [get_ports beta_19] -clock clk
set_input_delay 0.0 [get_ports beta_14] -clock clk
set_input_delay 0.0 [get_ports beta_10] -clock clk
set_input_delay 0.0 [get_ports beta_31] -clock clk
set_input_delay 0.0 [get_ports beta_17] -clock clk
set_input_delay 0.0 [get_ports beta_23] -clock clk
set_input_delay 0.0 [get_ports beta_4] -clock clk
set_input_delay 0.0 [get_ports beta_26] -clock clk

# input drivers
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_11] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_24] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_8] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_5] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_25] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_22] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_30] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_6] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_27] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_3] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_13] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_29] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_12] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_15] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_20] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_21] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_28] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_1] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_2] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_9] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_7] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports rst] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_16] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_18] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_0] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_19] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_14] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_10] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_31] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_17] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_23] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_4] -input_transition_fall 0.0 -input_transition_rise 0.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports beta_26] -input_transition_fall 0.0 -input_transition_rise 0.0

# output delays
set_output_delay 0.0 [get_ports cos_out_2] -clock clk
set_output_delay 0.0 [get_ports cos_out_13] -clock clk
set_output_delay 0.0 [get_ports sin_out_2] -clock clk
set_output_delay 0.0 [get_ports sin_out_17] -clock clk
set_output_delay 0.0 [get_ports sin_out_21] -clock clk
set_output_delay 0.0 [get_ports sin_out_8] -clock clk
set_output_delay 0.0 [get_ports sin_out_19] -clock clk
set_output_delay 0.0 [get_ports cos_out_30] -clock clk
set_output_delay 0.0 [get_ports cos_out_28] -clock clk
set_output_delay 0.0 [get_ports sin_out_20] -clock clk
set_output_delay 0.0 [get_ports cos_out_10] -clock clk
set_output_delay 0.0 [get_ports cos_out_17] -clock clk
set_output_delay 0.0 [get_ports cos_out_18] -clock clk
set_output_delay 0.0 [get_ports sin_out_16] -clock clk
set_output_delay 0.0 [get_ports cos_out_7] -clock clk
set_output_delay 0.0 [get_ports cos_out_11] -clock clk
set_output_delay 0.0 [get_ports sin_out_29] -clock clk
set_output_delay 0.0 [get_ports sin_out_9] -clock clk
set_output_delay 0.0 [get_ports sin_out_3] -clock clk
set_output_delay 0.0 [get_ports cos_out_4] -clock clk
set_output_delay 0.0 [get_ports sin_out_27] -clock clk
set_output_delay 0.0 [get_ports cos_out_12] -clock clk
set_output_delay 0.0 [get_ports cos_out_15] -clock clk
set_output_delay 0.0 [get_ports cos_out_19] -clock clk
set_output_delay 0.0 [get_ports sin_out_22] -clock clk
set_output_delay 0.0 [get_ports sin_out_7] -clock clk
set_output_delay 0.0 [get_ports cos_out_23] -clock clk
set_output_delay 0.0 [get_ports sin_out_31] -clock clk
set_output_delay 0.0 [get_ports sin_out_14] -clock clk
set_output_delay 0.0 [get_ports cos_out_26] -clock clk
set_output_delay 0.0 [get_ports cos_out_14] -clock clk
set_output_delay 0.0 [get_ports sin_out_23] -clock clk
set_output_delay 0.0 [get_ports sin_out_5] -clock clk
set_output_delay 0.0 [get_ports cos_out_25] -clock clk
set_output_delay 0.0 [get_ports sin_out_1] -clock clk
set_output_delay 0.0 [get_ports cos_out_1] -clock clk
set_output_delay 0.0 [get_ports cos_out_9] -clock clk
set_output_delay 0.0 [get_ports sin_out_24] -clock clk
set_output_delay 0.0 [get_ports cos_out_20] -clock clk
set_output_delay 0.0 [get_ports sin_out_30] -clock clk
set_output_delay 0.0 [get_ports sin_out_26] -clock clk
set_output_delay 0.0 [get_ports cos_out_0] -clock clk
set_output_delay 0.0 [get_ports sin_out_15] -clock clk
set_output_delay 0.0 [get_ports sin_out_28] -clock clk
set_output_delay 0.0 [get_ports sin_out_10] -clock clk
set_output_delay 0.0 [get_ports sin_out_13] -clock clk
set_output_delay 0.0 [get_ports cos_out_31] -clock clk
set_output_delay 0.0 [get_ports sin_out_0] -clock clk
set_output_delay 0.0 [get_ports cos_out_29] -clock clk
set_output_delay 0.0 [get_ports cos_out_3] -clock clk
set_output_delay 0.0 [get_ports cos_out_21] -clock clk
set_output_delay 0.0 [get_ports cos_out_6] -clock clk
set_output_delay 0.0 [get_ports cos_out_16] -clock clk
set_output_delay 0.0 [get_ports sin_out_11] -clock clk
set_output_delay 0.0 [get_ports cos_out_24] -clock clk
set_output_delay 0.0 [get_ports sin_out_4] -clock clk
set_output_delay 0.0 [get_ports sin_out_25] -clock clk
set_output_delay 0.0 [get_ports sin_out_18] -clock clk
set_output_delay 0.0 [get_ports sin_out_12] -clock clk
set_output_delay 0.0 [get_ports cos_out_27] -clock clk
set_output_delay 0.0 [get_ports cos_out_5] -clock clk
set_output_delay 0.0 [get_ports cos_out_8] -clock clk
set_output_delay 0.0 [get_ports cos_out_22] -clock clk
set_output_delay 0.0 [get_ports sin_out_6] -clock clk

# output loads
set_load -pin_load 4.0 [get_ports cos_out_2]
set_load -pin_load 4.0 [get_ports cos_out_13]
set_load -pin_load 4.0 [get_ports sin_out_2]
set_load -pin_load 4.0 [get_ports sin_out_17]
set_load -pin_load 4.0 [get_ports sin_out_21]
set_load -pin_load 4.0 [get_ports sin_out_8]
set_load -pin_load 4.0 [get_ports sin_out_19]
set_load -pin_load 4.0 [get_ports cos_out_30]
set_load -pin_load 4.0 [get_ports cos_out_28]
set_load -pin_load 4.0 [get_ports sin_out_20]
set_load -pin_load 4.0 [get_ports cos_out_10]
set_load -pin_load 4.0 [get_ports cos_out_17]
set_load -pin_load 4.0 [get_ports cos_out_18]
set_load -pin_load 4.0 [get_ports sin_out_16]
set_load -pin_load 4.0 [get_ports cos_out_7]
set_load -pin_load 4.0 [get_ports cos_out_11]
set_load -pin_load 4.0 [get_ports sin_out_29]
set_load -pin_load 4.0 [get_ports sin_out_9]
set_load -pin_load 4.0 [get_ports sin_out_3]
set_load -pin_load 4.0 [get_ports cos_out_4]
set_load -pin_load 4.0 [get_ports sin_out_27]
set_load -pin_load 4.0 [get_ports cos_out_12]
set_load -pin_load 4.0 [get_ports cos_out_15]
set_load -pin_load 4.0 [get_ports cos_out_19]
set_load -pin_load 4.0 [get_ports sin_out_22]
set_load -pin_load 4.0 [get_ports sin_out_7]
set_load -pin_load 4.0 [get_ports cos_out_23]
set_load -pin_load 4.0 [get_ports sin_out_31]
set_load -pin_load 4.0 [get_ports sin_out_14]
set_load -pin_load 4.0 [get_ports cos_out_26]
set_load -pin_load 4.0 [get_ports cos_out_14]
set_load -pin_load 4.0 [get_ports sin_out_23]
set_load -pin_load 4.0 [get_ports sin_out_5]
set_load -pin_load 4.0 [get_ports cos_out_25]
set_load -pin_load 4.0 [get_ports sin_out_1]
set_load -pin_load 4.0 [get_ports cos_out_1]
set_load -pin_load 4.0 [get_ports cos_out_9]
set_load -pin_load 4.0 [get_ports sin_out_24]
set_load -pin_load 4.0 [get_ports cos_out_20]
set_load -pin_load 4.0 [get_ports sin_out_30]
set_load -pin_load 4.0 [get_ports sin_out_26]
set_load -pin_load 4.0 [get_ports cos_out_0]
set_load -pin_load 4.0 [get_ports sin_out_15]
set_load -pin_load 4.0 [get_ports sin_out_28]
set_load -pin_load 4.0 [get_ports sin_out_10]
set_load -pin_load 4.0 [get_ports sin_out_13]
set_load -pin_load 4.0 [get_ports cos_out_31]
set_load -pin_load 4.0 [get_ports sin_out_0]
set_load -pin_load 4.0 [get_ports cos_out_29]
set_load -pin_load 4.0 [get_ports cos_out_3]
set_load -pin_load 4.0 [get_ports cos_out_21]
set_load -pin_load 4.0 [get_ports cos_out_6]
set_load -pin_load 4.0 [get_ports cos_out_16]
set_load -pin_load 4.0 [get_ports sin_out_11]
set_load -pin_load 4.0 [get_ports cos_out_24]
set_load -pin_load 4.0 [get_ports sin_out_4]
set_load -pin_load 4.0 [get_ports sin_out_25]
set_load -pin_load 4.0 [get_ports sin_out_18]
set_load -pin_load 4.0 [get_ports sin_out_12]
set_load -pin_load 4.0 [get_ports cos_out_27]
set_load -pin_load 4.0 [get_ports cos_out_5]
set_load -pin_load 4.0 [get_ports cos_out_8]
set_load -pin_load 4.0 [get_ports cos_out_22]
set_load -pin_load 4.0 [get_ports sin_out_6]

