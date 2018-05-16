'''
    File name      : 100_verilog_to_blif.py
    Author         : Jinwook Jung (jinwookjungs@gmail.com)
    Created on     : Sat 05 Aug 2017 02:35:14 PM KST
    Last modified  : 2017-08-09 00:19:16
    Description    : Convert a Verilog file int a BLIF format. The input
                     Verilog is assumed to be of ICCAD'15 Verilog format.
'''

#from __future__ import print_function
from time import gmtime, strftime
import sys

from verilog_to_blif_converter import *

def parse_cl():
    """ Parse command line and return dictionary. """

    import argparse
    parser = argparse.ArgumentParser(
                description='Converts a given gate-level verilog to a blif.')

    # Add arguments
    parser.add_argument(
            '-i', action="store", dest='src_v', required=True)
    parser.add_argument(
            '-o', action="store", dest='dest_blif', default='out.blif')
    parser.add_argument(
            '-t', action="store", dest='src_t', required=False)

    opt = parser.parse_args()
    return opt.src_v, opt.dest_blif, opt.src_t


if __name__ == '__main__':
    src, dest, asserts = parse_cl()

    print ("Provided design:  " + src)
    if asserts is not None:
        print ("Provided timing assertions: " + asserts)
    print ("Generated output: " + dest)

    sys.stdout.flush()

    blif_converter = BlifConverter()
    blif_converter.read_verilog(src)
    if asserts is not None:
        blif_converter.read_timing(asserts)
    blif_converter.write_blif(dest, asserts is not None)

