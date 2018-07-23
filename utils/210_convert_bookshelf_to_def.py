'''
    File name      : bookshelf_to_def.py
    Author         : Jinwook Jung (jinwookjungs@gmail.com)
    Created on     : Tue 08 Aug 2017 02:15:18 PM KST
    Last modified  : 2018-07-20 17:38:21
    Description    : Convert bookshelf files into a DEF.
'''
from __future__ import print_function, division
from time import gmtime, strftime
import sys, os

import verilog_parser
import def_parser
import lef_parser

class Node:
    """ A bookshelf Node. """
    def __init__(self, name, width=0.0, height=0.0, is_terminal=False,
                    x=0.0, y=0.0, orient='N'):
        self.name = name
        self.width, self.height= width, height
        self.is_terminal = is_terminal

        # Placement information
        self.x, self.y = x, y
        self.orient = orient

    def __str__(self):
        return "%s, (%.4f, %.4f), %r, (%.4f, %.4f), %s" % \
                (self.name, self.width, self.height, self.is_terminal,
                 self.x, self.y, self.orient)


class NodePin(Node):
    """ A bookshelf node that is a pin (terminal). """
    def __init__(self, name, direction):
        super().__init__(name)
        self.is_terminal = True
        self.direction = direction

    def get_def_string(self, x_scaler, y_scaler):
        x = self.x * x_scaler
        y = self.y * y_scaler

        return  \
        "  - %s + NET %s\n" \
        "    + DIRECTION %s\n" \
        "    + FIXED ( %d %d ) %s\n" \
        "        + LAYER metal3 ( 0 0 ) ( 380 380 ) ;" % \
        (self.name, self.name, self.direction, x, y, self.orient)


class NodeComponent(Node):
    """ A bookshelf node that is a component (non-terminal node). """
    def __init__(self, name, gate_type):
        super().__init__(name)
        self.gate_type = gate_type

    def get_def_string(self, x_scaler, y_scaler):
        x = self.x * x_scaler
        y = self.y * y_scaler

        fixed_placed = "FIXED" if self.is_terminal else "PLACED"
        return  \
        "  - %s %s\n" \
        "    + %s ( %d %d ) %s ;" % \
        (self.name, self.gate_type, fixed_placed, x, y, self.orient)


class BookshelfRow:
    """ A placement row. """
    def __init__(self, row_info):
        (self.coordinate, self.height, self.site_width, self.site_spacing,
        self.site_orient, self.site_symmetry, self.subrow_origin,
        self.num_sites) = row_info


class BookshelfToDEF:
    def __init__(self, src_lef, src_v, src_aux):
        self.node_dict, self.nets = dict(), list()
        self.row_list = list()

        self.src_lef, self.src_v = src_lef, src_v
        self.src_aux = src_aux

        self.lef, self.verilog = None, None

        """ Extract .nodes, .pl, .scl names. """
        nodes, pl, scl = (None,)*3
        with open(src_aux, 'r') as f:
            tokens = [t for l in f for t in l.split()
                        if t.endswith(('.nodes', '.pl', '.scl'))]
            for t in tokens:
                if t.endswith('.nodes'): nodes = t
                elif t.endswith('.pl'): pl = t
                else: scl = t
        try:
            assert len(tokens) == 3
        except AssertionError:
            sys.stderr.write("Error: invalid aux file.")
            raise SystemExit(-1)

        src_path = os.path.dirname(os.path.abspath(src_aux))
        self.src_nodes = src_path + '/' + nodes
        self.src_pl = src_path + '/' + pl
        self.src_scl = src_path + '/' + scl

    @property
    def design_name(self):
        return self.verilog.name

    @property
    def width_multiplier(self):
        return self.lef.metal_layer_dict[self.lef.m2_layer_name]

    @property
    def height_multiplier(self):
        return self.lef.metal_layer_dict[self.lef.m1_layer_name]

    @property
    def dbu_per_micron(self):
        return self.lef.units_distance_microns

    def initialize(self):
        """ Initialize internal data structure of Verilog and LEF. """
        def generate_node_dict(verilog, node_dict):
            """ Build up a name-to-type dictionary. """
            for i in verilog.input_dict.values():
                node_dict[i.name] = NodePin(i.name, 'INPUT')
            for o in verilog.output_dict.values():
                node_dict[o.name] = NodePin(o.name, 'OUTPUT')
            for i in verilog.instances:
                node_dict[i.name] = NodeComponent(i.name, i.gate_type)

        def generate_nets(verilog, nets):
            for w in verilog.wire_dict.values():
                try:
                    pins = [(w.source.owner.name, w.source.name)]
                except AttributeError:
                    pins = [("PIN", w.source.name)]

                for s in w.sinks:
                    try:
                        pins.append((s.owner.name, s.name))
                    except AttributeError:
                        pins.append(("PIN", s.name))

                nets.append(def_parser.DefNet(w.name, pins))

        print ("Parsing verilog: %s" % (self.src_v))
        self.verilog = verilog_parser.Module()
        self.verilog.read_verilog(self.src_v)
        self.verilog.construct_circuit_graph()
        self.verilog.print_stats()
        self.verilog.check_dangling_nets()

        generate_node_dict(self.verilog, self.node_dict)
        generate_nets(self.verilog, self.nets)

        print ("Parsing LEF: %s" % (self.src_lef))
        self.lef = lef_parser.Lef()
        self.lef.read_lef(self.src_lef)
        self.lef.print_stats()
        self.lef.m1_layer_name = 'metal1'
        self.lef.m2_layer_name = 'metal2'

    def convert_bookshelf_to_def(self, out_def):
        """ Convert given bookshelf into a def. """
        print ("Parsing bookshelf nodes: %s" % (self.src_nodes))
        self.parse_bookshelf_nodes()

        print ("Parsing bookshelf scl: %s" % (self.src_scl))
        self.parse_scl()

        # Get placement info
        print ("Parsing bookshelf pl: %s" % (self.src_pl))
        self.parse_pl()

        print ("Write def file")
        self.create_def_file(out_def)

    def parse_bookshelf_nodes(self):
        """ Find fixed component. """
        with open(self.src_nodes, 'r') as f:
            lines = [l for l in (line.strip() for line in f) if l]

        # Skip the first line: UCLA nodes ...
        for l in iter(lines[1:]):
            if l.startswith(('#')): continue
            tokens = l.split()
            if tokens[0] == 'NumNodes' or tokens[0] == 'NumTerminals':
                continue

            name, w, h = tokens[0], float(tokens[1]), float(tokens[2])
            try:
                n = self.node_dict[name]
            except KeyError:
                sys.stderr.write("Key Error: {}\n".format(name))
                sys.stderr.write(str(self.node_dict) + "\n")
                raise SystemExit(-1)

            n.width, n.height = w, h
            if n.__class__ == NodeComponent:
                n.is_terminal = True if len(tokens) == 4 else False

    def parse_scl(self):
        """ Parse bookshelf .scl file to get placemtn row information. """
        with open(self.src_scl, 'r') as f:
            lines = [l for l in (line.strip() for line in f) if l]

        # Skip the first line: UCLA scl ...
        lines_iter = iter(lines[1:])
        for l in lines_iter:
            if l.startswith('#'): continue
            tokens = l.split()
            if tokens[0] == 'NumRows':
                num_rows = int(tokens[2])

            elif tokens[0] == 'CoreRow':
                try: assert tokens[1] == 'Horizontal'
                except AssertionError:
                    sys.stderr.write("Unsupported bookshelf (scl) file.")
                    raise SystemExit(-1)

                row_info = [None]*8
                while True:
                    l = next(lines_iter)
                    tokens = l.split()
                    if tokens[0] == 'Coordinate':
                        row_info[0] = float(tokens[2])
                    elif tokens[0] == 'Height':
                        row_info[1] = float(tokens[2])
                    elif tokens[0] == 'Sitewidth':
                        row_info[2] = float(tokens[2])
                    elif tokens[0] == 'Sitespacing':
                        row_info[3] = float(tokens[2])
                    elif tokens[0] == 'Siteorient':
                        row_info[4] = tokens[2]
                    elif tokens[0] == 'Sitesymmetry':
                        row_info[5] = tokens[2]
                    elif tokens[0] == 'SubrowOrigin':
                        row_info[6] = float(tokens[2])
                        assert tokens[3] == 'NumSites'
                        row_info[7] = int(tokens[5])
                    elif tokens[0] == 'End':
                        break

                assert len([i for i in row_info if i is None]) == 0
                row = BookshelfRow(row_info)
                self.row_list.append(row)

        assert len(self.row_list) == num_rows

    def parse_pl(self):
        """ Parse bookshelf .pl file to get placement information. """
        with open(self.src_pl, 'r') as f:
            # read lines without blank lines
            lines = [l for l in (line.strip() for line in f) if l]

        # Skip the first line: UCLA nodes ...
        for l in iter(lines[1:]):
            if l.startswith('#'): continue

            tokens = l.split()
            assert len(tokens) >= 5
            name, orient = tokens[0], tokens[4]
            x, y = float(tokens[1]), float(tokens[2])
            orient = 'N'    # orient is fixed to N

            n = self.node_dict[name]
            n.x, n.y, n.orient = x, y, orient

    def create_def_file(self, filename):
        """ Create output DEF file. """
        dbu_per_micron    = self.dbu_per_micron
        width_multiplier  = self.width_multiplier
        height_multiplier = self.height_multiplier

        x_scaler = self.lef.units_distance_microns * width_multiplier
        y_scaler = self.lef.units_distance_microns * height_multiplier

        f = open(filename, 'w')

        f.write('# Written by BookshelfToDEF of OpenDesign Flow Database.\n\n')
        f.write("# Date: %s\n" % (strftime("%Y-%m-%d %H:%M:%S", gmtime())))
        f.write("# Format: ICCAD2015 placement contest\n\n")
        f.write('VERSION 5.7 ;\n')
        f.write('DIVIDERCHAR "/" ;\n')
        f.write('BUSBITCHARS "[]" ;\n')
        f.write('DESIGN %s ;\n' % (self.design_name))

        f.write("UNITS DISTANCE MICRONS %d ;\n\n" % (dbu_per_micron))

        # Note:
        #   Bookshelf width  = LEF width  / METAL pitch
        #   Bookshelf height = LEF height / METAL pitch
        #   DEF width = LEF width * dbu_per_micron
        #             = Bookshelf width * METAL pitch * dbu_per_micron
        #   DEF height = LEF height * dbu_per_micron
        #              = Bookshelf height * METAL pitch * dbu_per_micron

        die_llx, die_lly = 0, 0
        die_urx, die_ury = -1, -1

        site_name = self.lef.site_name
        def_row_string = list()

        for i, r in enumerate(self.row_list):
            llx_in_def = r.subrow_origin * dbu_per_micron * width_multiplier
            lly_in_def = r.coordinate * dbu_per_micron * height_multiplier

            width_in_def = r.site_width * dbu_per_micron * width_multiplier
            height_in_def = r.height * dbu_per_micron * height_multiplier
            site_spacing_in_def = r.site_spacing * dbu_per_micron * width_multiplier

            urx_in_def = llx_in_def + (width_in_def * r.num_sites)
            ury_in_def = lly_in_def + (height_in_def * 1)

            # Calculate the DIEAREA
            die_urx = urx_in_def if urx_in_def > die_urx else die_urx
            die_ury = ury_in_def if ury_in_def > die_ury else die_ury

            height_in_def = r.height * dbu_per_micron * height_multiplier

            def_row_string.append(
                    "ROW %s_SITE_ROW_%d %s %d %d %s DO %d BY %d STEP %d %d ;" \
                    % (site_name, i, site_name, llx_in_def, lly_in_def,
                    r.site_orient, r.num_sites, 1, int(site_spacing_in_def), 0))

        f.write("DIEAREA ( 0 0 ) ( %d %d ) ;\n\n" % (die_urx, die_ury))
        f.write('\n'.join(def_row_string))
        f.write("\n\n")

        node_list = list(self.node_dict.values())
        pins       = [n for n in node_list if n.__class__ is NodePin]
        components = [n for n in node_list if n.__class__ is NodeComponent]

        # PINS
        f.write("PINS %d ;\n" % (len(pins)))
        [f.write(p.get_def_string(x_scaler, y_scaler) + "\n") for p in pins]
        f.write("END PINS\n\n")

        # COMPONENTS
        f.write("COMPONENTS %d ;\n" % (len(components)))
        [f.write(c.get_def_string(x_scaler, y_scaler) + "\n") for c in components]
        f.write("END COMPONENTS\n\n")

        # NETS
        f.write("NETS %d ;\n" % (len(self.nets)))
        [f.write("{}\n".format(_)) for _ in self.nets]
        f.write("END NETS\n\n")

        f.write('END DESIGN\n')
        f.close()


if __name__ == '__main__':
    def parse_cl():
        import argparse
        parser = argparse.ArgumentParser(description='')
        parser.add_argument('--aux', dest='src_aux', required=True)
        parser.add_argument('--lef', dest='src_lef', required=True)
        parser.add_argument('--verilog', dest='src_v', required=True)
        parser.add_argument('--out_def', dest='out_def', default='out.def')
        opt = parser.parse_args()
        return opt

    opt = parse_cl()
    print ("Bookshelf  : " + opt.src_aux)
    print ("LEF        : " + opt.src_lef)
    print ("Netlist    : " + opt.src_v)
    print ("Output DEF : " + opt.out_def)
    print ("")

    converter = BookshelfToDEF(opt.src_lef, opt.src_v, opt.src_aux)
    converter.initialize()
    converter.convert_bookshelf_to_def(opt.out_def)

