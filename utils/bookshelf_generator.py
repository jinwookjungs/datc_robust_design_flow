'''
    File name      : book_shelf_generator.py
    Author         : Jinwook Jung
    Created on     : Sat 12 Aug 2017 10:09:16 PM KST
    Last modified  : 2017-08-12 23:40:21
    Description    :
'''
from __future__ import print_function, division
from time import gmtime, strftime
from copy import deepcopy
from math import ceil
import sys

import verilog_parser
import lef_parser

M1_LAYER_NAME = 'metal1'
M2_LAYER_NAME = 'metal2'


class Bookshelf:
    def __init__(self, src_v, src_lef, clock_port, util):
        self.src_v = src_v
        self.src_lef = src_lef
        self.clock_port = clock_port
        self.util = util

        self.verilog = None
        self.lef     = None

        self.total_area_in_bs = None
        self.width_divider    = 0.0
        self.height_divider   = 0.0

        self.die_width = 0.0
        self.die_height = 0.0

    def initialize(self):
        """ Initialize data structure. """
        print ("Parsing verilog: %s" % (self.src_v))
        self.verilog = verilog_parser.Module()
        self.verilog.read_verilog(self.src_v)
        self.verilog.construct_circuit_graph()
        self.verilog.print_stats()

        print ("Parsing LEF: %s" % (self.src_lef))
        self.lef = lef_parser.Lef()
        self.lef.set_m1_layer_name(M1_LAYER_NAME)
        self.lef.set_m2_layer_name(M2_LAYER_NAME)
        self.lef.read_lef(self.src_lef)
        self.lef.print_stats()

        self.site_width     = self.lef.site_width
        self.site_height    = self.lef.site_height
        self.width_divider  = self.lef.metal_layer_dict[M2_LAYER_NAME]
        self.height_divider = self.lef.metal_layer_dict[M1_LAYER_NAME]

    def write_bookshelf_nodes(self, filename='out'):
        """ Write down .nodes file. """
        f = open(filename + '.nodes', 'w')
        f.write('UCLA nodes 1.0\n', )
        f.write('# File header with version information, etc.\n')
        f.write('# Anything following "#" is a comment, '
                'and should be ignored\n\n')

        num_gates     = len(self.verilog.instances)
        num_inputs    = len(self.verilog.input_dict)
        num_outputs   = len(self.verilog.output_dict)
        num_terminals = num_inputs + num_outputs

        f.write("NumNodes\t:\t%d\n" % (num_gates + num_inputs + num_outputs))
        f.write("NumTerminals\t:\t%d\n\n" % (num_terminals))

        # Establish macro dictionary
        lef_macros = self.lef.macros
        big_blocks = {g.name : g for g in lef_macros \
                      if g.macro_class.startswith('BLOCK')}
        big_block_set = set(big_blocks.keys())
        std_cells = {g.name : g for g in lef_macros if g.macro_class == 'CORE'}
        std_cells_set = set(std_cells.keys())
        assert len(big_blocks) + len(std_cells) == len(lef_macros)

        self.total_area_in_bs = 0

        for g in self.verilog.instances:
            # Find width and height from LEF
            if g.gate_type in std_cells_set:
                lef_macro = std_cells[g.gate_type]

                width_in_bs  = ceil(lef_macro.width / self.width_divider)
                height_in_bs = ceil(lef_macro.height / self.height_divider)

                # total_width_in_bs += width_in_bs
                self.total_area_in_bs += width_in_bs * height_in_bs

                f.write("%-40s %15d %15d\n" % \
                        (g.name, int(width_in_bs), int(height_in_bs)))

            else:
                sys.stderr.write("Cannot find macro definition of %s. \n" % (g))
                raise SystemExit(-1)

        # Ports
        input_names = [_ for _ in self.verilog.input_dict.keys()]
        output_names = [_ for _ in self.verilog.output_dict.keys()]
        for terminal in input_names + output_names:
            port_width  = int(ceil(self.site_width  / self.width_divider))
            port_height = int(ceil(self.site_height / self.height_divider))
            f.write("%-40s %15d %15d %15s\n" \
                          % (terminal, port_width, port_height, 'terminal'))
        f.close()

    def write_bookshelf_nets(self, filename='out'):
        """ Write down bookshelf .nets file. """
        # Generate bookshelf nets
        f = open(filename + '.nets', 'w')
        f.write('UCLA nets 1.0\n')
        f.write('# File header with version information, etc.\n')
        f.write('# Anything following "#" is a comment, and should be ignored\n\n')

        # NumNets = #inputs + #outputs + #wires - 1
        inputs  = [_ for _ in self.verilog.input_dict.values()]
        outputs = [_ for _ in self.verilog.output_dict.values()]
        wires   = [_ for _ in self.verilog.wire_dict.values()]

        nets = wires
        f.write("NumNets\t:\t%d\n" % (len(nets)))

        # net dictionary - key: name, val: list( [name, I|O, x_offset, y_offset] )
        net_dict = {w.name : list() for w in wires}
        [net_dict[p.name].append([p.name, 'O', 0.0, 0.0]) for p in inputs]
        [net_dict[p.name].append([p.name, 'I', 0.0, 0.0]) for p in outputs]

        num_pins = len(inputs + outputs)

        # For fast lookup
        cell_dict = {lg.name: lg for lg in self.lef.macros}

        for g in self.verilog.instances:
            lef_cell = cell_dict[g.gate_type]
            lef_pin_dict = {p.name : p for p in lef_cell.pin_list}

            # Center coordinate
            node_x = (lef_cell.width / self.width_divider) * 0.5
            node_y = (lef_cell.height / self.height_divider) * 0.5

            # If you are using Python 3.5:
            # pin_name_to_net = {**g.ipin_name_to_net, **g.opin_name_to_net}
            # Else, please you the following code
            pin_name_to_net = dict(list(g.ipin_name_to_net.items())
                                   + list(g.opin_name_to_net.items()))

            for pin_name, net in pin_name_to_net.items():
                # FIXME: Clock net is excluded
                if net.name == self.clock_port:
                    continue
                num_pins += 1
                try:
                    lef_pin = lef_pin_dict[pin_name]
                except KeyError:
                    sys.stderr.write('Error: Verilog and LEF do not match:' \
                                     '(v, lef) = (%s, %s)\n' % (g, lef_cell))
                    raise SystemExit(-1)

                lef_pin_x = lef_pin.x / self.width_divider
                lef_pin_y = lef_pin.y / self.height_divider

                direction = lef_pin.direction
                x_offset = lef_pin_x - node_x
                y_offset = lef_pin_y - node_y

                net_dict[net.name].append([g.name, direction, x_offset, y_offset])

        f.write("NumPins\t:\t%d\n" % (num_pins))

        for net, pins in sorted(net_dict.items()):
            f.write("NetDegree : %d  %s\n" % (len(pins), net))
            for p in pins:
                f.write("        ")
                f.write("%s  %s : %11.4f %11.4f\n" % (p[0], p[1][0], p[2], p[3]))
            f.write("")

        f.close()

    def write_bookshelf_wts(self, filename='out', clock_weight=0):
        """ Write bookshelf .wts file. """
        f = open(filename + '.wts', 'w')
        f.write('UCLA wts 1.0\n')
        f.write('# File header with version information, etc.\n')
        f.write('# Anything following "#" is a comment, and should be ignored\n\n')

        # NumNets = #inputs + #outputs + #wires - 1
        inputs  = sorted([i.name for i in self.verilog.input_dict.values() \
                                 if i.name != self.clock_port])
        outputs = sorted([o.name for o in self.verilog.output_dict.values()])
        wires   = sorted([w.name for w in self.verilog.wire_dict.values()])

        f.write("%s %d\n" % (self.clock_port, clock_weight))
        for net_name in inputs + outputs + wires:
            f.write("%s %d\n" % (net_name, 1))
        f.close()

    def create_bookshelf_shapes(self, filename='out'):
        with open(filename + '.shapes', 'w') as f:
            f.write('shapes 1.0\n\n')
            f.write('NumNonRectangularNodes : 0\n\n')

    def create_bookshelf_scl(self, filename='out'):
        """
        Create bookshelf scl file with a given utilization
        """
        site_width_in_bs  = int(ceil(self.lef.site_width / self.width_divider))
        site_height_in_bs = int(ceil(self.lef.site_height / self.height_divider))
        site_spacing = site_width_in_bs

        placement_area = self.total_area_in_bs / self.util
        x_length = ceil(placement_area**0.5)
        y_length = ceil(x_length / site_height_in_bs) * site_height_in_bs
        num_row = ceil(x_length / site_height_in_bs)

        self.die_width, self.die_height = x_length, y_length

        site_orient = 'N'
        site_symmetry = 'Y'
        subrow_origin = 0

        f = open(filename + '.scl', 'w')
        f.write("UCLA scl 1.0\n\n")
        f.write("NumRows : %d\n\n" % (num_row))

        for i in range(num_row):
            f.write("CoreRow Horizontal\n")
            f.write("    Coordinate     : %d\n" % (i*site_height_in_bs))
            f.write("    Height         : %d\n" % (site_height_in_bs))
            f.write("    Sitewidth      : %d\n" % (site_width_in_bs))
            f.write("    Sitespacing    : %d\n" % (site_width_in_bs))
            f.write("    Siteorient     : N\n")
            f.write("    Sitesymmetry   : Y\n")
            f.write("    SubrowOrigin   : 0    ")
            f.write("    NumSites : %d\n" % (int(x_length)))
            f.write("End\n")

        f.close()

    def create_bookshelf_pl(self, filename='out'):
        """ Create bookshelf .pl file.

        Input and output ports are arbitrarily placed along the chip area.
        All the instances are placed at (0,0)
        """
        f = open(filename+ '.pl', 'w')
        f.write('UCLA pl 1.0\n\n')

        # nodes file - skip the first line and comments
        lines = [x.rstrip() for x in open(filename + '.nodes', 'r')
                 if not x.startswith('#')][1:]
        lines_iter = iter(lines)

        num_nodes, num_terminals = 0, 0
        terminal_list = list()

        site_width_in_bs  = int(ceil(self.site_width / self.width_divider))
        site_height_in_bs = int(ceil(self.site_height / self.height_divider))

        x_divisor = self.width_divider * self.lef.units_distance_microns
        y_divisor = self.height_divider * self.lef.units_distance_microns

        for line in lines:
            tokens = line.split()
            if len(tokens) < 2:
                continue

            elif tokens[0] == 'NumNodes':
                num_nodes = int(tokens[2])

            elif tokens[0] == 'NumTerminals':
                num_terminals = int(tokens[2])

            # Node definitions
            else:
                try:
                    assert len(tokens) in [3,4]

                except AssertionError:
                    sys.stderr.write("len(tokens) not in [3,4]\n")
                    raise SystemExit(-1)

                node_name = tokens[0]
                if 'terminal' in tokens[1:]:
                    terminal_list.append(node_name)
                else:
                    f.write("%s\t%d\t%d\t: N\n" % (node_name, 0, 0))

        try:
            assert len(terminal_list) == num_terminals
        except AssertionError:
            sys.stderr.write("len(terminal_list) (%d) != num_terminals (%d)\n"
                             % (len(terminal_list), num_terminals))
            raise SystemExit(-1)

        # Pin placement
        max_ports_in_edge = ceil(len(terminal_list) / 4)
        num_ports = [max_ports_in_edge] * 4

        diff = max_ports_in_edge * 4 - len(terminal_list)
        for i in range(diff):
            num_ports[3-i] -= 1

        south = [(i*(self.die_width / num_ports[0]), 0.0)
                 for i in range(num_ports[0])]
        east  = [(self.die_width, i*(self.die_height / num_ports[1]))
                 for i in range(num_ports[1])]
        north = [(self.die_width - i*(self.die_width / num_ports[2]), self.die_height)
                 for i in range(num_ports[2])]
        west  = [(0.0, self.die_height - i*(self.die_height / num_ports[3]))
                 for i in range(num_ports[3])]

        coords = south + east + north + west
        for terminal, p in zip(terminal_list, coords):
            x = int(round(p[0]/site_width_in_bs)) * site_width_in_bs
            y = int(round(p[1]/site_height_in_bs)) * site_height_in_bs
            f.write("%s\t%d\t%d\t: N\n" % (terminal, x, y))

        f.close()

    def write_bookshelf_aux(self, filename='out'):
        # bookshelf aux
        f= open(filename + '.aux', 'w')
        f.write("RowBasedPlacement : ")
        f.write("{0}.nodes {0}.nets {0}.wts {0}.pl {0}.scl {0}.shapes" \
                .format(filename))
        f.close()
        print ("Done.\n")

