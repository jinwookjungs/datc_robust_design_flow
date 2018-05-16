'''
    File name      : 400_generate_sizer_input.py
    Author         : Jinwook Jung
    Created on     : Sun 13 Aug 2017 09:07:02 PM KST
    Last modified  : 2017-08-14 12:49:03
    Description    : 
'''

from time import gmtime, strftime
import sys, re, os

import verilog_parser

BIG_BLOCK_PREFIX='block_'
TIE_CELLS=('vcc', 'vss')


def parse_cl():
    import argparse
    """ parse and check command line options
    @return: dict - optinos key/value
    """
    parser = argparse.ArgumentParser(
                description='Convert a given gate-level verilog to a blif.')

    # Add arguments
    parser.add_argument('-i', dest='src_v', required=True)
    parser.add_argument('-o', dest='dest_v', default='out.v')
    parser.add_argument('--clock', dest='clock', default='clk')
    parser.add_argument('--clock_period', dest='period', default='0.0')

    opt = parser.parse_args()
    return opt


def check_tie_cells(src):
    """ Check whether the source Verilog contains tie cells. """
    module = verilog_parser.Module()
    module.read_verilog(src)
    module.construct_circuit_graph()

    # Remove tie cells
    ties = list()

    for i in module.instances:
        if i.gate_type in TIE_CELLS:
            return True

    return False


if __name__ == '__main__':
    opt = parse_cl()
    src = opt.src_v

    print("Input file     : " + src)

    if check_tie_cells(src):
        print("Tie cells are found.")
        raise SystemExit(1)
    else:
        print("No tie cells.")

