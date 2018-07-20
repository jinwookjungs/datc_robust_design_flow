'''
    File name      : def_parser.py
    Author         : Jinwook Jung (jinwookjungs@gmail.com)
    Created on     : Tue 08 Aug 2017 02:15:18 PM KST
    Last modified  : 2018-07-20 17:38:44
    Description    : A DEF parser (for ISPD/ICCAD/TAU contest DEF files).
'''

from time import gmtime, strftime
import sys

__def_row_name__ = 'core_SITE_ROW'
__port_layer__ = 'metal3'
__big_block_prefix__ = 'BLK_'

class Def(object):
    def __init__(self):
        self.file_name = None
        self.version =  None
        self.divider_char = None
        self.bus_bit_chars = None
        self.design = None
        self.units_distance_microns = None
        self.die_area = (0, 0, 0, 0)

        self.rows = list()
        self.components = list()
        self.big_blocks = list()
        self.pins = list()
        self.nets = list()

        self.pin_pl_dict = dict()       # name : (x,y)
        self.component_pl_dict = dict() # name : (gate_type, is_fixed, (x,y))
        self.big_block_pl_dict = dict() # name : (gate_type, is_fixed, (x,y))

    def get_component_count(self):
        return len(self.components)

    def read_def(self, file_name):
        """ Read def and make a list of rows, components and pins """

        self.file_name = file_name
        with open(file_name, 'r') as f:
            lines = [l for l in (line.strip() for line in f) if l]
        lines_iter = iter(lines)

        for line in lines_iter:
            tokens = line.split()

            if tokens[0] == 'VERSION':
                self.version = tokens[1]

                while True:
                    tokens = next(lines_iter).split()

                    if tokens[0] == 'DIVIDERCHAR':
                        self.divider_char = tokens[1][1:-1]

                    elif tokens[0] == 'BUSBITCHARS':
                        self.bus_bit_chars = tokens[1][1:-1]

                    elif tokens[0] == 'DESIGN':     # FIXME
                        try:
                            assert self.design is None
                            self.design = tokens[1]
                        except AssertionError:
                            pass

                    elif tokens[0] == 'UNITS':
                        assert tokens[1] == 'DISTANCE'
                        assert tokens[2] == 'MICRONS'
                        self.units_distance_microns = int(tokens[3])

                    elif tokens[0] == 'DIEAREA':
                        llx, lly = int(tokens[2]), int(tokens[3])
                        urx, ury = int(tokens[6]), int(tokens[7])
                        self.die_area = (llx, lly, urx, ury)
                        break

            elif tokens[0] == 'ROW':
                # ROW name site x y N DO m BY n STEP dx dy
                name = tokens[1]
                site = tokens[2]
                x, y = int(tokens[3]), int(tokens[4])
                orient = tokens[5]
                m, n = int(tokens[7]), int(tokens[9])
                dx, dy = int(tokens[11]), int(tokens[12])

                row = DefRow(name, site, x, y, orient, m, n, dx, dy)
                self.rows.append(row)

            elif tokens[0] == 'COMPONENTS':
                num_components = int(tokens[1])

                while True:
                    tokens = next(lines_iter).split()
                    if tokens[0] == 'END' and tokens[1] == 'COMPONENTS':
                        break

                    # - name gate_type
                    #   + FIXED ( x y ) N ;
                    name = tokens[1]
                    gate_type = tokens[2]

                    tokens = next(lines_iter).split()
                    is_fixed = True if tokens[1] == 'FIXED' else False
                    x, y = (float(tokens[3]), float(tokens[4]))
                    orient = tokens[6]
                    component = DefComponent(name, gate_type, is_fixed,
                                             x, y, orient)

                    if gate_type.startswith(__big_block_prefix__):
                        print("BIG BLOCK - " + name)
                        self.big_blocks.append(component)
                        self.big_block_pl_dict[name] = (gate_type, is_fixed, (x,y))
                    else:
                        self.components.append(component)
                        self.component_pl_dict[name] = (gate_type, is_fixed, (x,y))

            elif tokens[0] == 'PINS':
                num_pins = int(tokens[1])

                while True:
                    tokens = next(lines_iter).split()
                    if tokens[0] == 'END' and tokens[1] == 'PINS':
                        break

                    # - name + NET net_name
                    #   + DIRECTION [INPUT|OUTPUT]
                    #   + FIXED ( x y ) N
                    #   + LAYER metal4 ( x y ) ( x y ) ;
                    pin_name = tokens[1]
                    net_name = tokens[4]

                    tokens = next(lines_iter).split()
                    direction = tokens[2]

                    tokens = next(lines_iter).split()
                    is_fixed = True if tokens[1] == 'FIXED' else False
                    x, y = (float(tokens[3]), float(tokens[4]))
                    orient = tokens[6]
                    tokens = next(lines_iter)
                    # layer, etc...

                    pin = DefPin(pin_name, net_name, direction, is_fixed,
                                 x, y, orient)

                    self.pins.append(pin)
                    self.pin_pl_dict[pin_name] = (x,y)

            elif tokens[0] == 'NETS':
                num_nets = int(tokens[1])

                while True:
                    line = next(lines_iter)

                    for c in ['-', '(', ')', ';']:
                        line = line.replace(c, '')

                    tokens = line.split()

                    if tokens[0] == 'END' and tokens[1] == 'NETS':
                        break

                    net_name = tokens[0]
                    pins = list()

                    i = 1
                    while i < len(tokens):
                        pins.append((tokens[i], tokens[i+1]))
                        i += 2

                    net = DefNet(net_name, pins)
                    self.nets.append(net)

        try:
            assert num_pins == len(self.pins)
        except AssertionError:
            sys.stderr.write('def_parser.py: num_pins(%d) != len(self.pins)(%d)\n'
                             % (num_pins, len(self.pins)))
            raise SystemExit(-1)

        try:
            assert num_components == len(self.components) + len(self.big_blocks)
        except AssertionError:
            sys.stderr.write('def_parser.py: num_components(%d) != %d + %d\n'
                             % (num_components, len(self.components), len(self.big_blocks)))
            raise SystemExit(-1)

    def write_def(self, file_name="out.def"):
        with open(file_name, 'w') as f:
            f.write("# Generated by def_parser.py, %s\n\n"
                    % (strftime("%Y-%m-%d %H:%M:%S", gmtime())))
            f.write("VERSION %s ;\n" % (self.version))
            f.write("DIVIDERCHAR \"%s\" ;\n" % (self.divider_char))
            f.write("BUSBITCHARS \"%s\" ;\n" % (self.bus_bit_chars))
            f.write("DESIGN %s ;\n" % (self.design))
            f.write("UNITS DISTANCE MICRONS %d ;\n\n"
                    % (self.units_distance_microns))
            f.write("DIEAREA ( %d %d ) ( %d %d ) ;\n\n" \
                    % (self.die_area[0], self.die_area[1], \
                       self.die_area[2], self.die_area[3]))

            # Write row
            for i, row in enumerate(self.rows):
                row_str = "ROW %s_%d core %d %d %s DO %d BY %d STEP %d %d ;" \
                             % (__def_row_name__, i, row.x, row.y, \
                                row.orient, row.m, row.n, row.dx, row.dy)
                f.write(row_str + '\n')
            f.write('\n')

            # Write pins
            f.write("PINS %d ;\n" % (len(self.pins)))

            sorted_pins = sorted(self.pins, key=lambda p : p.name)
            [f.write("{}\n".format(p)) for p in sorted_pins]
            f.write('END PINS\n\n')

            # Write components
            f.write("COMPONENTS %d ;\n" % (len(self.components) + len(self.big_blocks)))
            sorted_components = sorted(self.components, key=lambda c : c.name)
            [f.write("{}\n".format(c)) for c in sorted_components]

            # Write big blocks
            if len(self.big_blocks) > 0:
                sorted_blocks = sorted(self.big_blocks, key=lambda b : b.name)
                [f.write("{}\n".format(b)) for b in sorted_blocks]
            f.write('END COMPONENTS\n\n')

            # Write nets
            f.write("NETS %d ;\n" % (len(self.nets)))
            sorted_nets = sorted(self.nets, key=lambda n : n.name)
            [f.write("{}\n".format(n)) for n in sorted_nets]
            f.write('END NETS\n\n')

            f.write('END DESIGN\n\n')

    def print_stats(self):
        print ("==================================================")
        print ("DEF file               : %s" % (self.file_name))
        print ("DEF verision           : %s" % (self.version))
        print ("DIVIDERCHAR            : %s" % (self.divider_char))
        print ("BUSBITCHAR             : %s" % (self.bus_bit_chars))
        print ("DESIGN                 : %s" % (self.design))
        print ("UNITS DISTANCE MICRONS : %s" % (self.units_distance_microns))
        print ("DIE_AREA               : %s" % (str(self.die_area)))
        print ("Number of rows         : %d" % (len(self.rows)))
        print ("Number of components   : %d" % (len(self.components)))
        print ("Number of big_blocks   : %d" % (len(self.big_blocks)))
        print ("Number of pins         : %d" % (len(self.pins)))
        print ("==================================================\n")


class DefRow(object):
    def __init__(self, name, site, x, y, orient, m, n, dx, dy):
        self.name = name
        self.site = site
        self.x, self.y = x, y
        self.orient = orient
        self.m, self.n = m, n
        self.dx, self.dy = dx, dy

    def get_bookshelf_row_string(self, the_lef=None):
        if the_lef is None:
            sys.stderr.write('(E) get_bookshelf_row_string: the_lef is not given.\n')
            raise SystemExit(-1)

        # Scale factors to make width/height be the number of metal tracks
        # These values are assigned in parse_lef function
        width_divider  = the_lef.metal_layer_dict[the_lef.m2_layer_name]
        height_divider = the_lef.metal_layer_dict[the_lef.m1_layer_name]

        x_divisor = width_divider * the_lef.units_distance_microns
        y_divisor = height_divider * the_lef.units_distance_microns

        coordinate = round(self.y / y_divisor)
        site_height  = the_lef.site_height / height_divider
        site_width   = the_lef.site_width / width_divider
        site_spacing = self.dx / x_divisor
        assert site_width == site_spacing
        subrow_origin = round(self.x / x_divisor)
        num_sites = self.m

        return \
        "CoreRow Horizontal\n"  + \
        "    Coordinate   : %d\n" % (coordinate) + \
        "    Height       : %d\n" % (site_height) + \
        "    Sitewidth    : %d\n" % (site_width) + \
        "    Sitespacing  : %d\n" % (site_spacing) + \
        "    Siteorient   : N\n" + \
        "    Sitesymmetry : Y\n" + \
        "    SubrowOrigin : %d  NumSites : %d\n" % (subrow_origin, num_sites) + \
        "End\n"


class DefComponent(object):
    def __init__(self, name, gate_type, is_fixed, x, y, orient):
        self.name = name
        self.gate_type = gate_type
        self.is_fixed = is_fixed
        self.x, self.y = (x,y)
        self.orient = orient

    def __str__(self):
        fixed = 'FIXED' if self.is_fixed else 'PLACED'
        val =  "  - %s %s\n" % (self.name, self.gate_type)
        val += "    + %s ( %d %d ) %s ;" % (fixed, self.x, self.y, self.orient)
        return val


class DefPin(object):
    def __init__(self, name, net, direction, is_fixed, x, y, orient):
        self.name = name
        self.net = net
        self.direction = direction
        self.is_fixed = is_fixed
        self.x, self.y = (x, y)
        self.orient = orient
        self.layer = __port_layer__
        self.shape = [(0,0), (380,380)]

    def __str__(self):
        fixed = 'FIXED' if self.is_fixed else 'PLACED'
        val =  "  - %s + NET %s\n" % (self.name, self.net)
        val += "    + DIRECTION %s\n" % (self.direction)
        val += "    + %s ( %d %d ) %s\n" % (fixed, self.x, self.y, self.orient)
        val += "      + LAYER metal3 ( %d %d ) ( %d %d ) ;" \
                % (self.shape[0][0], self.shape[0][1], \
                   self.shape[1][0], self.shape[1][1])

        return val


class DefNet(object):
    def __init__(self, name, pins):
        self.name = name
        self.pins = pins    # List of (component, pin) pair

    def __str__(self):
        val = "    - {}".format(self.name)
        for p in self.pins:
            val += " ( {} {} )".format(p[0], p[1])
        val += " ;"
        return val


if __name__ == '__main__':
    """ Test """
    def parse_cl():
        import argparse
        parser = argparse.ArgumentParser(description='A DEF parser.')
        parser.add_argument('-i', action="store", dest='src', required=True)
        opt = parser.parse_args()
        return opt

    opt = parse_cl()
    src = opt.src

    the_def = Def()
    the_def.read_def(src)
    the_def.print_stats()
    the_def.write_def("test")
