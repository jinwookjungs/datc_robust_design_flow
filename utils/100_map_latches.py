'''
    File name      : 100_map_latches.py
    Author         : Jinwook Jung (jinwookjungs@gmail.com)
    Created on     : Mon 07 Aug 2017 02:41:23 PM KST
    Last modified  : 2017-08-09 00:19:21
    Description    : Map latches of an ABC netlist to the specified lib cell.
'''

from time import gmtime, strftime
from textwrap import wrap
import sys, math, argparse

from latch_mapper import *

def parse_cl():
    """ Parse command line and return dictionary. """
    parser = argparse.ArgumentParser(
                description='Map all latches of the ABC synthesis result.')

    # Add arguments
    parser.add_argument('-i', dest='src_v', required=True)
    parser.add_argument('--latch', dest='latch_cell', required=True)
    parser.add_argument('--clock', dest='clock_port')
    parser.add_argument('--sdc', dest='input_sdc')
    parser.add_argument('-o', dest='dest_v', default='out_lmapped.v')
    opt = parser.parse_args()

    if opt.input_sdc is None and opt.clock_port is None:
        parser.error("At least one of --sdc and -c required.")
        raise SystemExit(-1)

    elif opt.input_sdc is not None:
        try:
            # Example: create_clock [get_port <clock_port>] ...
            create_clock = [x.rstrip() for x in open(opt.input_sdc, 'r') \
                                        if x.startswith('create_clock')][0]
            tokens = create_clock.split()
            opt.clock_port = tokens[tokens.index('[get_ports') + 1][:-1]

        except ValueError:
            parser.error("Cannot find the clock port in %s." % (opt.input_sdc))
            raise SystemExit(-1)

        except TypeError:
            parser.error("Cannot open file %s." % (opt.input_sdc))
            raise SystemExit(-1)

    else:   # opt.clock_port is not None
        pass    # Nothing done.

    return opt


if __name__ == '__main__':
    opt = parse_cl()
    src_v = opt.src_v
    latch_cell = opt.latch_cell
    clock_port = opt.clock_port
    dest_v = opt.dest_v

    print ("Input file:  " + src_v)
    print ("Latch cell:  " + latch_cell)
    print ("Clock port:  " + clock_port)
    print ("Output file: " + dest_v)
    sys.stdout.flush()

    mapper = LatchMapper(clock_port, latch_cell)
    mapper.read_verilog(src_v)
    mapper.map_latches(dest_v)
