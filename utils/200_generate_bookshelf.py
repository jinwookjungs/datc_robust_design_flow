'''
    File name      : 200_generate_bookshelf.py
    Author         : Jinwook Jung
    Created on     : Sat 12 Aug 2017 10:26:29 PM KST
    Last modified  : 2017-08-12 22:26:29
    Description    : 
'''

from bookshelf_generator import *

def parse_cl():
    """ parse and check command line options
    @return: dict - optinos key/value
    """
    import argparse
    from argparse import ArgumentTypeError

    def utilization(x):
        x = float(x)
        if x < 0.1 or x > 0.99:
            raise ArgumentTypeError("Utilization(%r) not in [0.1, 0.99]." % (x))
        return x

    parser = argparse.ArgumentParser(
                description='Generate a set of bookshelf files.')

    parser.add_argument('-i', dest='src_v', required=True)
    parser.add_argument('--lef', dest='src_lef', required=True)
    parser.add_argument('--clock', dest='clock_port')
    parser.add_argument('--sdc', dest='input_sdc')

    parser.add_argument('--util', type=utilization, dest='utilization', 
                        default=0.7, 
                        help="Utilization (in 0.1, 0.99).")

    parser.add_argument('-o', dest='dest_name', help="Base name of output files")

    opt = parser.parse_args()

    # Find clock port
    if opt.input_sdc is None and opt.clock_port is None:
        parser.error("at least one of --sdc and --clock required.")
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

    if opt.dest_name is None:
        opt.dest_name = opt.src_v[opt.src_v.rfind('/')+1:opt.src_v.find('.v')]

    return opt


if __name__ == '__main__':
    opt = parse_cl()

    src_v, src_lef = opt.src_v, opt.src_lef
    src_lef = opt.src_lef
    clock_port = opt.clock_port
    src_sdc = opt.input_sdc
    utilization = opt.utilization
    dest = opt.dest_name

    # Command line parameter checking
    print ("Input Verilog     :  %s" % (src_v))
    print ("Input LEF         :  %s" % (src_lef))
    print ("Utilization       :  %.1f %%" % (float(utilization)*100))

    if src_sdc is not None:
        print ("Input SDC         :  %s" % (src_sdc))
        print ("Clock port        :  %s" % (clock_port))
        print ("\t Clock port was extracted from the input SDC.")
    else:
        print ("Clock port        :  %s" % (clock_port))

    print ("Output file       :  %s" % (dest))
    print ("")

    bookshelf = Bookshelf(src_v, src_lef, clock_port, utilization)
    bookshelf.initialize()
    bookshelf.write_bookshelf_nodes(dest)
    bookshelf.write_bookshelf_nets(dest)
    bookshelf.write_bookshelf_wts(dest)
    bookshelf.create_bookshelf_shapes(dest)
    bookshelf.create_bookshelf_scl(dest)
    bookshelf.create_bookshelf_pl(dest)
    bookshelf.write_bookshelf_aux(dest)
