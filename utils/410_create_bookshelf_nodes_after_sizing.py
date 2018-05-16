
from time import gmtime, strftime
from math import ceil
import sys, re, os

import verilog_parser
import lef_parser


def parse_cl():
    import argparse
    """ parse and check command line options
    @return: dict - optinos key/value
    """
    parser = argparse.ArgumentParser(
                description='Convert a given gate-level verilog to a blif.')

    # Add arguments
    parser.add_argument('--bs_nodes', dest='src_nodes', required=True)
    parser.add_argument('--verilog', dest='src_v', required=True)
    parser.add_argument('--lef', dest='src_lef', required=True)
    parser.add_argument('-o', dest='dest_nodes', default='out.nodes')

    opt = parser.parse_args()
    return opt


def create_bs_nodes_after_sizing (src_nodes, src_v, src_lef, dest):

    # read files
    print ("Read verilog.")
    module = verilog_parser.Module()
    module.read_verilog(src_v)
    module.construct_circuit_graph()
    module.print_stats()

    print ("Read lef.")
    the_lef = lef_parser.Lef()
    the_lef.read_lef(src_lef)
    the_lef.print_stats()

    with open(src_nodes, 'r') as f:
        lines = [l.strip() for l in f]
    lines_iter = iter(lines)

    #
    instance_dict = {i.name : i.gate_type for i in module.instances}
    lef_macro_dict = {m.name : m.width for m in the_lef.macros}
    site_width = the_lef.sites[0].width

    with open(dest, 'w') as f:
        for line in lines_iter:
            if line == "":
                f.write('\n')
                continue

            tokens = line.split()
            instance_name = tokens[0]

            try:
                gate_type = instance_dict[instance_name]
            except KeyError:
                f.write(line + '\n')
                continue

            if gate_type in ('PI', 'PO'):
                f.write(line + '\n')
                continue

            width = lef_macro_dict[gate_type] / site_width
            # width = round(width) # FIXME
            width = ceil(width) # FIXME
            f.write("%-40s %15d %15d\n" % (instance_name, int(width), 9))
        

if __name__ == '__main__':
    opt = parse_cl()
    src_nodes = opt.src_nodes
    src_v = opt.src_v
    src_lef = opt.src_lef
    dest = opt.dest_nodes

    print ("Bookshelf Nodes: " + src_nodes)
    print ("Sizing result  : " + src_v)
    print ("LEF file       : " + src_lef)
    print ("Output file    : " + dest)
    sys.stdout.flush()

    create_bs_nodes_after_sizing(src_nodes, src_v, src_lef, dest)

