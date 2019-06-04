# Synopsys Design Constraints Format

# clock definition
create_clock -name clk -period 1500.0 [get_ports clk]

# input delays
set_input_delay 0.0 [get_ports x1542] -clock clk
set_input_delay 0.0 [get_ports x1203] -clock clk
set_input_delay 0.0 [get_ports x806] -clock clk
set_input_delay 0.0 [get_ports x1557] -clock clk
set_input_delay 0.0 [get_ports x130646] -clock clk
set_input_delay 0.0 [get_ports x1390] -clock clk
set_input_delay 0.0 [get_ports x1424] -clock clk
set_input_delay 0.0 [get_ports x1564] -clock clk
set_input_delay 0.0 [get_ports x1511] -clock clk
set_input_delay 0.0 [get_ports x1006] -clock clk
set_input_delay 0.0 [get_ports x1486] -clock clk
set_input_delay 0.0 [get_ports x1398] -clock clk
set_input_delay 0.0 [get_ports x1459] -clock clk
set_input_delay 0.0 [get_ports x130629] -clock clk
set_input_delay 0.0 [get_ports x130652] -clock clk
set_input_delay 0.0 [get_ports x130647] -clock clk
set_input_delay 0.0 [get_ports x1572] -clock clk
set_input_delay 0.0 [get_ports x130631] -clock clk
set_input_delay 0.0 [get_ports x1587] -clock clk
set_input_delay 0.0 [get_ports x130641] -clock clk
set_input_delay 0.0 [get_ports x1322] -clock clk
set_input_delay 0.0 [get_ports x130638] -clock clk
set_input_delay 0.0 [get_ports x1501] -clock clk
set_input_delay 0.0 [get_ports x1209] -clock clk
set_input_delay 0.0 [get_ports x1432] -clock clk
set_input_delay 0.0 [get_ports x1215] -clock clk
set_input_delay 0.0 [get_ports x130633] -clock clk
set_input_delay 0.0 [get_ports x1155] -clock clk
set_input_delay 0.0 [get_ports x130637] -clock clk
set_input_delay 0.0 [get_ports x1451] -clock clk
set_input_delay 0.0 [get_ports x1519] -clock clk
set_input_delay 0.0 [get_ports x1062] -clock clk
set_input_delay 0.0 [get_ports x1358] -clock clk
set_input_delay 0.0 [get_ports x1261] -clock clk
set_input_delay 0.0 [get_ports x940] -clock clk
set_input_delay 0.0 [get_ports x130632] -clock clk
set_input_delay 0.0 [get_ports x906] -clock clk
set_input_delay 0.0 [get_ports x1417] -clock clk
set_input_delay 0.0 [get_ports x1034] -clock clk
set_input_delay 0.0 [get_ports x130648] -clock clk
set_input_delay 0.0 [get_ports x1101] -clock clk
set_input_delay 0.0 [get_ports x130649] -clock clk
set_input_delay 0.0 [get_ports x1580] -clock clk
set_input_delay 0.0 [get_ports x130636] -clock clk
set_input_delay 0.0 [get_ports x130644] -clock clk
set_input_delay 0.0 [get_ports x1406] -clock clk
set_input_delay 0.0 [get_ports x1822] -clock clk
set_input_delay 0.0 [get_ports x1494] -clock clk
set_input_delay 0.0 [get_ports x977] -clock clk
set_input_delay 0.0 [get_ports x1286] -clock clk
set_input_delay 0.0 [get_ports x1126] -clock clk
set_input_delay 0.0 [get_ports x130654] -clock clk
set_input_delay 0.0 [get_ports x130657] -clock clk
set_input_delay 0.0 [get_ports x1231] -clock clk
set_input_delay 0.0 [get_ports x837] -clock clk
set_input_delay 0.0 [get_ports x130645] -clock clk
set_input_delay 0.0 [get_ports x1550] -clock clk
set_input_delay 0.0 [get_ports x130656] -clock clk
set_input_delay 0.0 [get_ports x130651] -clock clk
set_input_delay 0.0 [get_ports x130655] -clock clk
set_input_delay 0.0 [get_ports x1345] -clock clk
set_input_delay 0.0 [get_ports x1479] -clock clk
set_input_delay 0.0 [get_ports x130635] -clock clk
set_input_delay 0.0 [get_ports x1527] -clock clk
set_input_delay 0.0 [get_ports x130640] -clock clk
set_input_delay 0.0 [get_ports x1351] -clock clk
set_input_delay 0.0 [get_ports x130634] -clock clk
set_input_delay 0.0 [get_ports x1374] -clock clk
set_input_delay 0.0 [get_ports x1382] -clock clk
set_input_delay 0.0 [get_ports x130639] -clock clk
set_input_delay 0.0 [get_ports x1467] -clock clk
set_input_delay 0.0 [get_ports x130630] -clock clk
set_input_delay 0.0 [get_ports x130642] -clock clk
set_input_delay 0.0 [get_ports x130643] -clock clk
set_input_delay 0.0 [get_ports x1193] -clock clk
set_input_delay 0.0 [get_ports x1366] -clock clk
set_input_delay 0.0 [get_ports x868] -clock clk
set_input_delay 0.0 [get_ports x889] -clock clk
set_input_delay 0.0 [get_ports x1534] -clock clk
set_input_delay 0.0 [get_ports x130650] -clock clk
set_input_delay 0.0 [get_ports x130653] -clock clk
set_input_delay 0.0 [get_ports x1595] -clock clk
set_input_delay 0.0 [get_ports x1443] -clock clk

# input drivers
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1542] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1203] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x806] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1557] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130646] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1390] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1424] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1564] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1511] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1006] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1486] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1398] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1459] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130629] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130652] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130647] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1572] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130631] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1587] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130641] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1322] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130638] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1501] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1209] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1432] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1215] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130633] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1155] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130637] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1451] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1519] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1062] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1358] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1261] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x940] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130632] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x906] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1417] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1034] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130648] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1101] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130649] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1580] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130636] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130644] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1406] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1822] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1494] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x977] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1286] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1126] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130654] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130657] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1231] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x837] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130645] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1550] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130656] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130651] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130655] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1345] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1479] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130635] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1527] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130640] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1351] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130634] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1374] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1382] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130639] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1467] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130630] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130642] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130643] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1193] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1366] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x868] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x889] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1534] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130650] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x130653] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1595] -input_transition_fall 5.0 -input_transition_rise 5.0
set_driving_cell -lib_cell in01f80 -pin o [get_ports x1443] -input_transition_fall 5.0 -input_transition_rise 5.0

# output delays
set_output_delay 220.0 [get_ports x718] -clock clk
set_output_delay 220.0 [get_ports x124] -clock clk
set_output_delay 220.0 [get_ports x30] -clock clk
set_output_delay 220.0 [get_ports x589] -clock clk
set_output_delay 220.0 [get_ports x397] -clock clk
set_output_delay 220.0 [get_ports x84] -clock clk
set_output_delay 220.0 [get_ports x217] -clock clk
set_output_delay 220.0 [get_ports x765] -clock clk
set_output_delay 220.0 [get_ports x361] -clock clk
set_output_delay 220.0 [get_ports x149] -clock clk
set_output_delay 220.0 [get_ports x138] -clock clk
set_output_delay 220.0 [get_ports x315] -clock clk
set_output_delay 220.0 [get_ports x522] -clock clk
set_output_delay 220.0 [get_ports x172] -clock clk
set_output_delay 220.0 [get_ports x786] -clock clk
set_output_delay 220.0 [get_ports x131] -clock clk
set_output_delay 220.0 [get_ports x681] -clock clk
set_output_delay 220.0 [get_ports x476] -clock clk
set_output_delay 220.0 [get_ports x145] -clock clk
set_output_delay 220.0 [get_ports x638] -clock clk
set_output_delay 220.0 [get_ports x390] -clock clk
set_output_delay 220.0 [get_ports x63] -clock clk
set_output_delay 220.0 [get_ports x379] -clock clk
set_output_delay 220.0 [get_ports x447] -clock clk
set_output_delay 220.0 [get_ports x96] -clock clk
set_output_delay 220.0 [get_ports x179] -clock clk
set_output_delay 220.0 [get_ports x699] -clock clk
set_output_delay 220.0 [get_ports x195] -clock clk
set_output_delay 220.0 [get_ports x0] -clock clk
set_output_delay 220.0 [get_ports x106] -clock clk
set_output_delay 220.0 [get_ports x420] -clock clk
set_output_delay 220.0 [get_ports x101] -clock clk
set_output_delay 220.0 [get_ports x620] -clock clk
set_output_delay 220.0 [get_ports x187] -clock clk
set_output_delay 220.0 [get_ports x538] -clock clk
set_output_delay 220.0 [get_ports x264] -clock clk
set_output_delay 220.0 [get_ports x744] -clock clk
set_output_delay 220.0 [get_ports x234] -clock clk
set_output_delay 220.0 [get_ports x114] -clock clk
set_output_delay 220.0 [get_ports x77] -clock clk
set_output_delay 220.0 [get_ports x657] -clock clk
set_output_delay 220.0 [get_ports x342] -clock clk
set_output_delay 220.0 [get_ports x494] -clock clk
set_output_delay 220.0 [get_ports x14] -clock clk
set_output_delay 220.0 [get_ports x287] -clock clk
set_output_delay 220.0 [get_ports x561] -clock clk
set_output_delay 220.0 [get_ports x249] -clock clk
set_output_delay 220.0 [get_ports x38] -clock clk

# output loads
set_load -pin_load 4.0 [get_ports x718]
set_load -pin_load 4.0 [get_ports x124]
set_load -pin_load 4.0 [get_ports x30]
set_load -pin_load 4.0 [get_ports x589]
set_load -pin_load 4.0 [get_ports x397]
set_load -pin_load 4.0 [get_ports x84]
set_load -pin_load 4.0 [get_ports x217]
set_load -pin_load 4.0 [get_ports x765]
set_load -pin_load 4.0 [get_ports x361]
set_load -pin_load 4.0 [get_ports x149]
set_load -pin_load 4.0 [get_ports x138]
set_load -pin_load 4.0 [get_ports x315]
set_load -pin_load 4.0 [get_ports x522]
set_load -pin_load 4.0 [get_ports x172]
set_load -pin_load 4.0 [get_ports x786]
set_load -pin_load 4.0 [get_ports x131]
set_load -pin_load 4.0 [get_ports x681]
set_load -pin_load 4.0 [get_ports x476]
set_load -pin_load 4.0 [get_ports x145]
set_load -pin_load 4.0 [get_ports x638]
set_load -pin_load 4.0 [get_ports x390]
set_load -pin_load 4.0 [get_ports x63]
set_load -pin_load 4.0 [get_ports x379]
set_load -pin_load 4.0 [get_ports x447]
set_load -pin_load 4.0 [get_ports x96]
set_load -pin_load 4.0 [get_ports x179]
set_load -pin_load 4.0 [get_ports x699]
set_load -pin_load 4.0 [get_ports x195]
set_load -pin_load 4.0 [get_ports x0]
set_load -pin_load 4.0 [get_ports x106]
set_load -pin_load 4.0 [get_ports x420]
set_load -pin_load 4.0 [get_ports x101]
set_load -pin_load 4.0 [get_ports x620]
set_load -pin_load 4.0 [get_ports x187]
set_load -pin_load 4.0 [get_ports x538]
set_load -pin_load 4.0 [get_ports x264]
set_load -pin_load 4.0 [get_ports x744]
set_load -pin_load 4.0 [get_ports x234]
set_load -pin_load 4.0 [get_ports x114]
set_load -pin_load 4.0 [get_ports x77]
set_load -pin_load 4.0 [get_ports x657]
set_load -pin_load 4.0 [get_ports x342]
set_load -pin_load 4.0 [get_ports x494]
set_load -pin_load 4.0 [get_ports x14]
set_load -pin_load 4.0 [get_ports x287]
set_load -pin_load 4.0 [get_ports x561]
set_load -pin_load 4.0 [get_ports x249]
set_load -pin_load 4.0 [get_ports x38]

