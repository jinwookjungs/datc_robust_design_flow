'''
    File name      : latch_mapper.py
    Author         : Jinwook Jung (jinwookjungs@gmail.com)
    Created on     : Mon 07 Aug 2017 02:41:23 PM KST
    Last modified  : 2017-08-13 12:11:25
    Description    : Provides the LatchMapper class to generate a netlist with 
                     all latches mapped. Given the verilog output from the 
                     ABC, LatchMapper generates a netlist in which all latches 
                     are mapped to the specified library cell.
'''
from time import gmtime, strftime
from textwrap import wrap
import sys, math, argparse

TIE_HI = 'vcc'
TIE_LO = 'vss'

class Latch(object):
    """ Contain information about a latch cell. """
    def __init__(self, instance_id, d, q, clk, gtype):
        self.instance_id = instance_id
        self.d = d
        self.q = q
        self.clk = clk
        self.gtype = gtype

    def print_latch(self, digit):
        return "%s l%0*d ( .d(%s), .o(%s), .ck(%s) );" % \
                (self.gtype, digit, self.instance_id, 
                 self.d, self.q, self.clk)


class LatchMapper(object):
    """ Latch-mapped netlist generator. """
    def __init__(self, clock_port, latch_cell):
        self.name, self.input_file = None, None

        self.clock_port = clock_port
        self.latch_cell = latch_cell 
        self.inputs = list()
        self.outputs = list()
        self.wires = list()
        self.assigns = list()
        self.instances = list()     # Instances and assign statements
        self.latches = list()

    def read_verilog(self, filename):
        """ Read a Verilog file that is written by write_verilog of ABC. """
        self.input_file = filename 

        with open(filename, 'r') as f:
            lines = [l for l in (line.strip() for line in f) if l]
        lines_iter = iter(lines)

        def add_tokens(lines_iter, dest):
            line = next(lines_iter)
            tokens = line.split()
            [dest.append(t.rstrip(',;')) for t in tokens]
            return not line.endswith(';')

        inputs, outputs, wires = list(), list(), list()

        for line in lines_iter:
            tokens = line.split()

            if tokens[0] == '//':
                continue

            elif tokens[0] == 'module':
                self.name = tokens[1]
                while not next(lines_iter).endswith(');'):
                    continue    # Skip lines
 
            elif tokens[0] == 'input':
                [inputs.append(t.rstrip(',;')) for t in tokens[1:]]
                if line.endswith(';'):
                    continue
                while add_tokens(lines_iter, inputs):
                    pass

            elif tokens[0] == 'output':
                [outputs.append(t.rstrip(',;')) for t in tokens[1:]]
                if line.endswith(';'):
                    continue
                while add_tokens(lines_iter, outputs):
                    pass

            elif tokens[0] in ('wire', 'reg'):
                [wires.append(t.rstrip(',;')) for t in tokens[1:]]
                if line.endswith(';'):
                    continue
                while add_tokens(lines_iter, wires):
                    pass

            elif tokens[0] == 'assign':
                self.assigns.append(line)

            elif tokens[0] == 'initial':
                # Skip the initial block
                while True:
                    line = next(lines_iter)
                    tokens = line.split()
                    if tokens[0] == 'end':
                        break

            elif tokens[0] == 'always':
                latch_count = 1
                while True:
                    line = next(lines_iter)
                    tokens = line.split()
                    if tokens[0] == 'end' and len(tokens) == 1:
                        break

                    instance_id = latch_count
                    d, q = tokens[2].rstrip(';'), tokens[0]
                    latch = Latch(instance_id, d, q, self.clock_port, 
                                  self.latch_cell)
                    self.latches.append(latch)
                    latch_count += 1

            elif tokens[0] == 'endmodule':
                break

            else:
                # Format cell instantiations as ICCAD contest format
                i1 = line.find('(')  # Find the first left parenthesis (
                i2 = line.find(');')  # Find the end of the instantiation );

                gate_type, instance = line[:i1].split()
                if gate_type == 'one':
                    gate_type = 'vcc'
                elif gate_type == 'zero':
                    gate_type = 'vss'

                instantiation = "%s %s ( %s );" \
                                % (gate_type, instance, line[i1+1:i2])

                self.instances.append(instantiation)

        self.inputs = sorted(list(set(inputs) - {self.clock_port, 'clock'}))
        self.outputs = sorted(outputs)
        self.wires = sorted(set(wires) - set(inputs) - set(outputs))

    def map_latches(self, filename):
        """ Map latch cells into the given netlist. """
        f = open(filename, 'w')
        f.write("// Latch-mapped netlist written by map_latches.py, %s\n"
                     "// Written ISPD/ICCAD/TAU contest Verilog format. \n" % \
                            (strftime("%Y-%m-%d %H:%M:%S", gmtime())))  
        f.write("//    Input file:  " + self.input_file + "\n")
        f.write("//    Latch cell:  " + self.latch_cell + "\n")
        f.write("//    Clock port:  " + self.clock_port + "\n")
        f.write("//    Output file: " + filename + "\n\n")

        # Module declaration
        f.write("module %s (\n" % (self.name))
        f.write(self.clock_port + ',\n')
        f.write(',\n'.join(self.inputs) + ',\n')
        f.write(',\n'.join(self.outputs) + '\n);\n')
        
        # PIs and POs
        f.write('\n// Start PIs\n')
        f.write('input %s;\n' % (self.clock_port))
        [f.write('input %s;\n' % (i)) for i in self.inputs]
        f.write('\n// Start POs\n')
        [f.write('output %s;\n' % (o)) for o in self.outputs]

        # Wires
        f.write('\n// Start wires\n')
        f.write('wire %s;\n' % (self.clock_port))
        [f.write('wire %s;\n' % (w)) for w in self.inputs]
        [f.write('wire %s;\n' % (w)) for w in self.outputs]
        [f.write('wire %s;\n' % (w)) for w in self.wires]

        f.write('\n// Start cells\n')
        [f.write(i + '\n') for i in self.instances]

        # Latches
        digit = int(math.log(len(self.latches),10)) + 1
        f.write('\n'.join([l.print_latch(digit) for l in self.latches]))
        f.write('\n')

        if len(self.assigns) == 0:
            f.write('\nendmodule\n')
            f.close()
            return

        digit = int(math.log(len(self.assigns),10)) + 1

        for i, assign in enumerate(self.assigns):
            tokens = assign.split()
            identifier, value = tokens[1], tokens[3].rstrip(';');
            # Only assignments to 1-bit constants are supported
            try:
                assert value  in ("1'b0", "1'b1")
            except AssertionError:
                sys.stderr.write("(E) Unsupported assignment: %s\n" % assign)
                raise SystemExit(-1)

            inst_name = ("t%0*d" % (digit, i))
            if value == "1'b0":
                f.write("%-7s %s ( .o(%s) );\n" % (TIE_HI, inst_name, identifier))
            else:
                f.write("%-7s %s ( .o(%s) );\n" % (TIE_LO, inst_name, identifier))

        f.write('\nendmodule\n')
        f.close()


if __name__ == '__main__':
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
            parser.error("Either --sdc or --clock required.")
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

