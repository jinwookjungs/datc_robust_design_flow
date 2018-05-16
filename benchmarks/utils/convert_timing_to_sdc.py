'''
    File name      : convert_timing_to_sdc.py
    Author         : Jinwook Jung
    Created on     : Sun 06 Aug 2017 11:54:57 PM KST
    Last modified  : 2017-08-06 23:54:57
    Description    : Convert .timing of TAU'17 to .sdc.
'''

from time import gmtime, strftime
import sys, re, os

tau17_clock_period_dict = { \
    "ac97_ctrl"              : 1500,
    "aes_core"               : 1800,
    "b19_iccad"              : 6800,
    "cordic_ispd"            : 7200,
    "cordic2_ispd"           : 7200,
    "crc32d16N"              : 900,
    "des_perf_ispd"          : 18200,
    "des_perf"               : 26900,
    "edit_dist_ispd"         : 28000,
    "edit_dist2_ispd"        : 28000,
    "fft_ispd"               : 6700,
    "leon2_iccad"            : 57600,
    "leon3mp_iccad"          : 31500,
    "matrix_mult_ispd"       : 9100,
    "mgc_edit_dist_iccad"    : 28000,
    "mgc_matrix_mult_iccad"  : 9400,
    "netcard_iccad"          : 51500,
    "pci_bridge32"           : 3200,
    "systemcaes"             : 3100,
    "systemcdes"             : 2000,
    "tv80"                   : 3200,
    "usb_funct"              : 2200,
    "usb_phy_ispd"           : 500,
    "vga_lcd_iccad"          : 7800,
    "vga_lcd"                : 7200,
    "wb_dma"                 : 1400
}

class Clock:
    def __init__(self, port, period):
        self.port = port
        self.period = period


class Constraint:
    def __init__(self, port, er, ef, lr, lf):
        self.port = port
        self.er, self.ef = er, ef       # Early rise/fall
        self.lr, self.lf = lr, lf       # Late rise/fall


class Load:
    def __init__(self, port, pin_load):
        self.port = port
        self.pin_load = pin_load


def convert(bench_name, timing, sdc, clock_port, time_scaler=1, load_scaler=1):
    """ Convert .timing to .sdc. """
    clock = None
    at_list, slew_list = list(), list()
    rat_list, load_list = list(), list()

    clock_orig = None

    try:
        period = tau17_clock_period_dict[bench_name]
    except KeyError:
        period = None

    with open(timing, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]

    for line in lines:
        tokens = line.split()
        
        if tokens[0] == 'clock':
            port = tokens[1]
            if period is None:
                period = float(tokens[2])*time_scaler
            clock_orig = port

            if clock_port is None:
                clock = Clock(port, period)
            else:
                clock = Clock(clock_port, period)
            continue

        elif tokens[0] in ('at', 'rat', 'slew'):
            port = tokens[1]
            er, ef, lr, lf = [float(t)*time_scaler for t in tokens[2:]]
            constraint = Constraint(port, er, ef, lr, lf)

            # Timing constraints on clock port are skipped (USizer will crush.)
            if port == clock_orig:
                continue

            if tokens[0] == 'at':
                at_list.append(constraint)

            elif tokens[0] == 'slew':
                slew_list.append(constraint)

            elif tokens[0] == 'rat':
                rat_list.append(constraint)

        elif tokens[0] == 'load':
            port, pin_load = tokens[1], float(tokens[2])*load_scaler
            load_list.append(Load(port, pin_load))

    with open(sdc, 'w') as f:
        f.write("# Synopsys Design Constraints Format\n\n")
        f.write("# clock definition\n")
        f.write("create_clock -name %s -period %.1f [get_ports %s]\n" \
                % (clock.port, clock.period, clock.port))

        f.write("\n# input delays\n")
        for at in at_list:
            f.write("set_input_delay %.1f [get_ports %s] -clock %s\n"
                    % (at.lr, at.port, clock.port))

        f.write("\n# input drivers\n")
        for slew in slew_list:
            f.write("set_driving_cell -lib_cell %s -pin %s [get_ports %s]" \
                    % ("in01f80", "o", slew.port))
            f.write(" -input_transition_fall %.1f -input_transition_rise %.1f\n" \
                    % (slew.lf, slew.lr))

        f.write("\n# output delays\n")
        for rat in rat_list:
            f.write("set_output_delay %.1f [get_ports %s] -clock %s\n"
                    % (rat.lr, rat.port, clock.port))

        f.write("\n# output loads\n")
        for load in load_list:
            f.write("set_load -pin_load %.1f [get_ports %s]\n" \
                    % (load.pin_load, load.port))

        f.write("\n")

    # Scale .timing file
    with open(timing, 'w') as f:
        # Clock definition
        f.write("clock %s %d 50\n" % (clock.port, round(clock.period)))

        # Arrival time 
        for at in at_list:
            f.write("at %s %d %d %d %d\n" \
                    % (at.port, round(at.er), round(at.ef), 
                       round(at.lr), round(at.lf)))

        # Slew
        for slew in slew_list:
            f.write("slew %s %d %d %d %d\n" \
                    % (slew.port, round(slew.er), round(slew.ef), 
                       round(slew.lr), round(slew.lf)))

        # Required arrival time
        for rat in rat_list:
            f.write("rat %s %d %d %d %d\n" \
                    % (rat.port, round(rat.er), round(rat.ef), 
                       round(rat.lr), round(rat.lf)))

        # Output load
        for load in load_list:
            f.write("load %s %.1f\n" \
                    % (load.port, load.pin_load))


if __name__ == '__main__':
    def parse_cl():
        import argparse
        parser = argparse.ArgumentParser(description='')
        parser.add_argument('--timing', dest='timing', required=True)
        parser.add_argument('--sdc', dest='sdc', default='out.v')
        parser.add_argument('--time_scaler', dest='time_scaler', default='20')
        parser.add_argument('--load_scaler', dest='load_scaler', default='5')

        return parser.parse_args()

    opt = parse_cl()
    timing, sdc = opt.timing, opt.sdc
    time_scaler = float(opt.time_scaler)
    load_scaler = float(opt.load_scaler)

    print ("Input file  : " + timing)
    print ("Output file : " + sdc)
    print ("Clock port  : clk")
    print ("Time scaler : %.3f" % (time_scaler))
    print ("Load scaler : %.3f" % (load_scaler))
    sys.stdout.flush()

    bench_name = timing[:-7]
    convert(bench_name, timing, sdc, clock_port="clk")

