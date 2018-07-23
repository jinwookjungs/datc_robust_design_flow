'''
    File name      : verilog_parser.py
    Author         : Jinwook Jung (jinwookjungs@gmail.com)
    Created on     : Wed 09 Aug 2017 01:03:08 AM KST
    Last modified  : 2017-08-14 01:58:07
    Description    : A Verilog parser (ISPD/ICCAD/TAU contest verilog format).
    Supported Verilog input format:
    module <circuit name> (
        <input 1>,
        ...
        <input n>,
        <output 1>,
        ...
        <output m>);
        input <input 1>;
        ...
        input <input i>;
        output <output 1>;
        ...
        output <output j>;
        wire <wire 1>;
        ...
        wire <wire k>;      // k = #inputs + #outputs + #wires
        <type> <instance name> ( .<pin> (<net>), ... );
        ...
        assign <net> = [1'b0|1'b1];     // Constant assignment
        ...
    endmodule
'''
from __future__ import print_function
import sys, math, operator
from time import gmtime, strftime

BLOCK_PREFIX = 'block_'
TIE_HI = 'vcc'
TIE_LO = 'vss'
LATCH  = 'ms00f80'
OUT_PIN_NAME = ('o', 'q')


class Vertex:
    def __init__(self, name, owner):
        self.name = name
        self.owner = owner          # Port or Instance
        self.ie_dict = dict()       # Incoming edge dictionary
        self.oe_dict = dict()       # Outgoing edge dictionary

    @property
    def in_degree(self):
        return len(self.ie_dict)

    @property
    def out_degree(self):
        return len(self.oe_dict)

    @property
    def degree(self):
        return self.in_degree + self.out_degree

    def __str__(self):
        return "Vertex name=%s" % (self.name)


class HyperEdge:
    def __init__(self, name, owner):
        self.name   = name
        self.owner  = owner         # Port or Wire
        self.source = None          # A vertex
        self.sink_dict = dict()     # A set of vertices (k: name, v: Vertex)

    @property
    def cardinality(self):
        num_sinks = len(self.sink_dict)
        if self.source is None:
            return num_sinks
        else:
            return num_sinks + 1

    def __str__(self):
        if self.source is None:
            source_name = 'None'
        else:
            source_name = self.source.name

        return "HyperEdge(%s): " % (self.name) \
               + " source=%s, sinks={" % (source_name) \
               + "%s}" % (', '.join([s.name for s in self.sink_dict.values()]))


class CircuitGraph:
    """ A circuit graph. """
    def __init__(self, name):
        self.name = name
        self.vertex_map = dict()    # Vertex name to Vertex
        self.edge_map   = dict()    # Edge name to Edge

    @property
    def vertice(self):
        return vertex_map.values()

    @property
    def edges(self):
        return edge_map.values()

    @property
    def net_degrees(self):
        edges = self.edge_map.values()
        degrees = sorted([(e.cardinality, e.name) for e in edges], \
                          key=lambda k:k[0])
        return degrees

    def print_vertices_and_edges(self):
        for k, v in self.vertex_map.items():
            print(v)
        for k, v in self.edge_map.items():
            print(v)


class Pin:
    """ An instance pin. """
    def __init__(self, name, direction, net_name, owner):
        self.name      = name
        self.direction = direction      # ['input'|'output']
        self.net_name  = net_name       # Name of the net
        self.owner     = owner          # The Instance it belongs to
        self.net = None                 # An instance of Net

    def __str__(self):
        return "Pin(name=%s, owner=%s, direction=%s, net_name=%s)" \
               % (self.name, self.owner.name, self.direction, self.net_name)

    @property
    def owner_name(self):
        return self.owner.name

    @property
    def full_name(self):
        return "{}/{}".format(self.owner.name, self.name)


class Port(Pin):
    """ A module port. """
    def __init__(self, name, direction):
        super().__init__(name, direction, name, owner=None)

    def __str__(self):
        return "Port(name=%s, direction=%s, net_name=%s)" \
               % (self.name, self.direction, self.net_name)

    @property
    def owner_name(self):
        return self.name

    @property
    def full_name(self):
        return "{}".format(self.name)


class Instance:
    """ Verilog gate information. """
    def __init__(self, gate_type, name):
        self.gate_type = gate_type
        self.name = name
        self.ipins = list()                 # List of Pins (direction=input)
        self.opins = list()                 # List of Pins (direction=output)

        self.ipin_name_to_net = dict()      # Input pin name to Net dict
        self.opin_name_to_net = dict()      # Output pin name to Net dict

    def __str__(self):
        return "%s %s %s %s" % \
               (self.gate_type, self.name,
                self.ipin_name_to_net, self.opin_name_to_net)

    def get_instantiation_string(self):
        val = "%-8s %s ( " % (self.gate_type, self.name)
        output_pin_string, input_pin_string = list(), list()

        for k,v in self.opin_name_to_net.items():
            output_pin_string.append(".%s(%s)" % (k,v.name))

        for k,v in self.ipin_name_to_net.items():
            input_pin_string.append(".%s(%s)" % (k,v.name))

        input_pin_string.sort()

        if len(output_pin_string) + len(input_pin_string) == 1:
            val += (output_pin_string + input_pin_string)[0] + ' );'
        else:
            output_pins = ', '.join(sorted(output_pin_string))
            input_pins = ', '.join(sorted(input_pin_string))
            val += output_pins + ', ' + input_pins + ' );'

        return val


class Wire:
    """ A net that connects a source pin to sink pin(s). """
    def __init__(self, name):
        self.name = name
        self.source = None
        self.sinks = list()

    @property
    def degree(self):
        return len(self.sinks) + (1 if self.source is not None else 0)

    def __str__(self):
        sink_names = ' '.join([s.full_name for s in self.sinks])
        return "Wire(%s): source=%s, sinks={%s}" \
                % (self.name, self.source.full_name, sink_names)


class Module(object):
    def __init__(self, clock_port=None):
        self.name = None
        self.input_dict  = dict()            # List of Ports
        self.output_dict = dict()
        self.wire_dict   = dict()            # List of Wires
        self.clock_port  = clock_port        # Clock port name

        self.instances = list()
        self.assigns = list()   # List of tuples of (id, val)

        self.circuit_graph = None

    def print_stats(self):
        print("==================================================")
        print("Name               : %s" % (self.name))
        print("Name of clock port : %s" % (self.clock_port))
        print("Number of inputs   : %d" % (len(self.input_dict)))
        print("Number of outputs  : %d" % (len(self.output_dict)))
        print("Number of wires    : %d" % (len(self.wire_dict)))
        print("Number of instances: %d" % (len(self.instances)))

        big_blocks = [i for i in self.instances \
                      if i.gate_type.startswith(BLOCK_PREFIX)]
        if not len(big_blocks) == 0:
            print("Number of macros   : %d" % (len(big_blocks)))

        tie_cells = [i for i in self.instances if i.gate_type in (TIE_LO, TIE_HI)]
        if len(tie_cells) > 0:
            print("Number of tie cells: %d" % (len(tie_cells)))

        net_degrees = self.circuit_graph.net_degrees
        max_cardinality = max(net_degrees, key=lambda k:k[0])
        avg_cardinality = sum([d[0] for d in net_degrees])
        avg_cardinality /= float(len(net_degrees))

        if self.clock_port is not None:
            clk_net = self.circuit_graph.edge_map[self.clock_port]
            print("No of clock sinks  : %d" % (clk_net.cardinality))

        print("Maximum edge cardinality: %d (%s)" \
              % (max_cardinality[0], max_cardinality[1]))
        print("Average edge cardinality: %f" % (avg_cardinality))

        print("==================================================\n")

    def _create_tie_cells(self):
        # Create TIE cells
        if len(self.assigns) == 0:
            return
        digit = int(math.log(len(self.assigns),10)) + 1

        for i, a in enumerate(self.assigns):
            identifier, value = a[0], a[1]
            inst_name = ("t%0*d" % (digit, i))
            if value == "1'b0":
                tie = Instance(TIE_HI, inst_name)
                pin = Pin('o', 'output', identifier, tie)
                tie.opins.append(pin)
                self.instances.append(tie)
            else:
                tie = Instance(TIE_LO, inst_name)
                pin = Pin('o', 'output', identifier, tie)
                tie.opins.append(pin)
                self.instances.append(tie)

    def read_verilog(self, filename):
        """ Read verilog and get netlist info.

        Read a given verilog file and the create a circuit graph along with
        the dictionaries of inputs/outputs/wires and instances.
        The given verilog must follow the ISPD/ICCAD/TAU specification.
        """
        # read file without blank lines
        with open(filename, 'r') as f:
            lines = [l for l in (line.strip() for line in f) if l]
        lines_iter = iter(lines)

        # Get input, output, wire names
        inputs, outputs, wires = list(), list(), list()

        for line in lines_iter:
            tokens = line.split()

            if line.startswith('//'):
                continue

            elif tokens[0] == 'module':
                self.name = tokens[1]
                while not next(lines_iter).endswith(');'):
                    continue    # Skip lines

            elif tokens[0] == 'input':
                name = tokens[1].rstrip(';')  # strip semicolon
                inputs.append(name)

            elif tokens[0] == 'output':
                name = tokens[1].rstrip(';')  # strip semicolon
                outputs.append(name)

            elif tokens[0] == 'wire':
                while True:
                    name = tokens[1].rstrip(';')  # strip semicolon
                    wires.append(name)
                    line = next(lines_iter)
                    if not line.startswith('wire '):
                        break
                    else:
                        tokens = line.split()
                break   # stop iteration

            elif tokens[0] == 'reg':
                sys.stderr.write('Error: not a gate-level netlist.\n')
                raise SystemExit(-1)

            else:
                continue

        # Gate instance extraction
        for line in lines_iter:
            if line.startswith('//'):
                continue

            for c in ['.', ',', '(', ')', ';']:
                line = line.replace(c, ' ')

            tokens = line.split()

            if tokens[0] == 'endmodule':
                break

            elif tokens[0] == 'assign':
                identifier, value = tokens[1], tokens[3].rstrip(';');
                # Only assignments to 1-bit constants are supported
                try:
                    assert value  in ("1'b0", "1'b1")
                except AssertionError:
                    sys.stderr.write("(E) Unsupported assignment: %s\n", line)
                    raise SystemExit(-1)

                self.assigns.append((identifier, value))
                continue

            else:
                gate_type, inst_name = tokens[0], tokens[1]
                self.instances.append(Instance(gate_type, inst_name))

                it = iter(tokens[2:])
                for (pin_name, net_name) in zip(it, it):
                    if pin_name in OUT_PIN_NAME:
                        pin = Pin(pin_name, 'output', net_name, self.instances[-1])
                        self.instances[-1].opins.append(pin)
                    else:
                        pin = Pin(pin_name, 'input', net_name, self.instances[-1])
                        self.instances[-1].ipins.append(pin)

        # Create tie cells
        self._create_tie_cells()

        self.input_dict  = {i : Port(i, 'input') for i in inputs}
        self.output_dict = {o : Port(o, 'output') for o in outputs}

        # The dictionary wire_dict also includes input and output wires.
        self.wire_dict   = {w : Wire(w) for w in wires}

        # Populate member variales of wires
        for k,v in self.input_dict.items():
            wire = self.wire_dict[k]
            wire.source = v

        for k,v in self.output_dict.items():
            wire = self.wire_dict[k]
            wire.sinks.append(v)

        for inst in self.instances:
            for ipin in inst.ipins:
                net_name = ipin.net_name
                wire = self.wire_dict[net_name]
                wire.sinks.append(ipin)

            for opin in inst.opins:
                net_name = opin.net_name
                wire = self.wire_dict[net_name]
                wire.source = opin

        assert len(self.input_dict) > 0
        assert len(self.output_dict) > 0
        assert len(self.wire_dict) > 0
        assert len(self.instances) > 0

    def construct_circuit_graph(self):
        """ Construct circuit graph G(V,E). """
        self.circuit_graph = CircuitGraph(self.name)
        G = self.circuit_graph

        for a in self.assigns:
            identifier, value = a[0], a[1]
            if value == "1'b1":
                vertex = Vertex(identifier, TIE_HI)

            elif value == "1'b0":
                vertex = Vertex(identifier, TIE_LO)

        # Create vertices and edges
        #   Vertices: {PIs} + {POs} + {Instances}
        #   Edges:    {PI nets} + {PO nets} + {wires}
        for v in self.input_dict.values():
            vertex = Vertex(v.name, v)
            G.vertex_map[vertex.name] = vertex

        for v in self.output_dict.values():
            vertex = Vertex(v.name, v)
            G.vertex_map[vertex.name] = vertex

        for v in self.instances:
            vertex = Vertex(v.name, v)
            G.vertex_map[vertex.name] = vertex

        for port in self.input_dict.values():
            edge = HyperEdge(port.name, port)
            G.edge_map[edge.name] = edge

            vertex = G.vertex_map[port.name]
            vertex.oe_dict[edge.name] = edge
            edge.source = vertex

        for port in self.output_dict.values():
            edge = HyperEdge(port.name, port)
            G.edge_map[edge.name] = edge

            vertex = G.vertex_map[port.name]
            vertex.ie_dict[edge.name] = edge
            edge.sink_dict[vertex.name] = vertex

        ios = list(self.input_dict.keys()) + list(self.output_dict.keys())
        for w in self.wire_dict.values():
            # Exclude input and output wires
            if w.name in ios:
                continue

            edge = HyperEdge(w.name, w)
            G.edge_map[edge.name] = edge

        # Connect vertices
        for i in self.instances:
            #print("Connecting vertices for %s" % (i.name))
            vertex = G.vertex_map[i.name]

            for ipin in i.ipins:
                #print("\tInput pin: %s (net=%s)" % (ipin.name, ipin.net_name))
                net_name = ipin.net_name
                edge = G.edge_map[net_name]
                #print("\t\tEdge found: %s" % (edge.name))

                ipin.net = edge
                i.ipin_name_to_net[ipin.name] = edge

                vertex.ie_dict[edge.name] = edge
                edge.sink_dict[vertex.name] = vertex

            for opin in i.opins:
                #print("\tOutput pin: %s (net=%s)" % (opin.name, opin.net_name))
                net_name = opin.net_name
                edge = G.edge_map[net_name]
                #print("\t\tEdge found: %s" % (edge.name))

                opin.net = edge
                i.opin_name_to_net[opin.name] = edge

                vertex.oe_dict[edge.name] = edge
                edge.source = vertex

    def check_dangling_nets(self):
        edges = self.circuit_graph.edge_map.values()
        floating_edges = [e for e in edges if e.cardinality <= 1]
        print("Num dangling nets: %d" % len(floating_edges))

        if len(floating_edges) > 0:
            print("First 5 dangling nets")
            [print("\t%s" % e) for e in floating_edges[:5]]

    def remove_dangling_nets(self):
        """ Remove dangling nets by (1) removing input port, or (2) creating
        an output port for a latch output. Other types of dangling nets cannot
        be handled by this function.
        """
        G = self.circuit_graph
        dangling = [e for e in G.edge_map.values() if e.cardinality <= 1]

        dangling_lo = list()
        dangling_ip = list()
        for edge in dangling:
            if edge.owner.__class__ == Wire:
                # Owner is a wire
                if edge.source.owner.gate_type == LATCH:
                    dangling_lo.append(edge.name)

                    # Remove the wire
                    self.wire_dict.pop(edge.name)

                    # Create an output port having the same name as the wire
                    port_name = edge.name
                    new_port = Port(port_name, 'output')
                    self.output_dict[port_name] = new_port

                    # Connect
                    new_vertex = Vertex(port_name, new_port)
                    new_vertex.ie_dict[edge.name] = edge
                    G.vertex_map[port_name] = new_vertex
                    edge.sink_dict[new_vertex.name] = new_vertex

                else:
                    sys.stderr.write("(E) Cannot handle %s." % (edge.name))
                    raise SystemExit(-1)

            elif edge.owner.__class__ == Port:
                # Owner is a port (direction=input)
                if edge.source is None:
                    sys.stderr.write("(E) Cannot handle %s." % (edge.name))
                    raise SystemExit(-1)

                if edge.owner.direction == 'output':
                    sys.stderr.write("(E) Cannot handle %s." % (edge.name))
                    raise SystemExit(-1)

                dangling_ip.append(edge.name)

                # Remove the input port
                self.input_dict.pop(edge.name)

                # (TODO) Remove the vertex and edges
                G.edge_map.pop(edge.name)
                G.vertex_map.pop(edge.name)

        print("Number of dangling latch outputs: %d" % len(dangling_lo))
        print("Number of dangling input ports  : %d" % len(dangling_ip))
        if len(dangling_lo) > 0:
            print("\tDangling latch outputs are connected to output ports", end=' ')
            print("(e.g. %s)." % (dangling_lo[0]))
        if len(dangling_ip) > 0:
            print("\tDangling input ports are removed", end=' ')
            print("(e.g. %s)." % (dangling_ip[0]))

    def write_verilog(self, filename='out.v'):
        """ Write an output verilog file. """
        inputs = [i for i in self.input_dict.keys() if i != self.clock_port]
        outputs = [o for o in self.output_dict.keys()]
        wires = [w for w in self.wire_dict.keys() if w != self.clock_port]

        # Exclude inputs and outputs from wires
        wires = list(set(wires) - set(inputs + outputs))

        inputs  = sorted(inputs)
        outputs = sorted(outputs)
        wires   = sorted(wires)

        with open(filename, 'w') as f:
            f.write("// Written by verilog_parser.py of OpenDesign Flow Database.\n")
            f.write("// Date: %s\n" % (strftime("%Y-%m-%d %H:%M:%S", gmtime())))
            f.write("// Format: ICCAD2015 placement contest\n\n")
            f.write("module %s (\n" % (self.name))
            if self.clock_port is not None:
                f.write(self.clock_port + ',\n')
            f.write(',\n'.join(inputs) + ',\n')
            f.write(',\n'.join(outputs) + '\n);\n')
            f.write('\n// Start PIs\n')
            if self.clock_port is not None:
                f.write('input %s;\n' % (self.clock_port))
            [f.write('input %s;\n' % (i)) for i in inputs]
            f.write('\n// Start POs\n')
            [f.write('output %s;\n' % (o)) for o in outputs]
            f.write('\n// Start wires\n')
            if self.clock_port is not None:
                f.write('wire %s;\n' % (self.clock_port))
            [f.write('wire %s;\n' % (w)) for w in inputs]
            [f.write('wire %s;\n' % (w)) for w in outputs]
            [f.write('wire %s;\n' % (w)) for w in wires]
            f.write('\n// Start cells\n')
            [f.write(g.get_instantiation_string() + '\n') for g in self.instances]
            f.write('\nendmodule\n')

    def write_sdc(self, filename='out.sdc', clock_period=50000.0):
        """ Write a sdc template file. """
        inputs = [i for i in self.input_dict.keys() if i != self.clock_port]
        outputs = [o for o in self.output_dict.keys()]
        inputs = sorted(inputs)
        outputs = sorted(outputs)

        if self.clock_port is None:
            sys.stderr.write("No clock port is specified. Quitting...\n")
            return

        with open(filename, 'w') as f:
            f.write('# Synopsys Design Constraints Format\n\n'
                    '# clock definition\n')
            f.write("create_clock -name mclk -period %.2f [get_ports %s]\n\n" \
                    % (clock_period, self.clock_port))

            f.write('# input delays\n')
            [f.write("set_input_delay 0.0 [get_ports %s] -clock mclk\n" % (i)) for i in inputs]
            f.write("\n")
            f.write('# input drivers\n')
            [f.write("set_driving_cell -lib_cell in01f80 -pin o [get_ports %s]"
                     " -input_transition_fall 80.0 -input_transition_rise 80.0\n" % (i)) for i in inputs]
            f.write("\n")
            f.write('# output delays\n')
            [f.write("set_output_delay 0.0 [get_ports %s] -clock mclk\n" % (o)) for o in outputs]
            f.write("\n")
            f.write('# output loads\n')
            [f.write("set_load -pin_load 4.0 [get_ports %s]\n" % (o)) for o in outputs]


def extract_pin_and_net(token):
    """ token should be .PIN(NET), or .PIN(NET) """
    # replace .,() with blank
    for c in ('.', ',', '(', ')'):
        token = token.replace(c, ' ')

    token = token.strip().split()
    pin, net = token[0], token[1]
    return pin, net


if __name__ == '__main__':
    """ Test """
    def parse_cl():
        import argparse
        parser = argparse.ArgumentParser(description='A Verilog parser.')
        parser.add_argument('-i', dest='src', required=True)
        parser.add_argument('--clock_port', dest='clock', required=False)
        parser.add_argument('-o', dest='dest', required=False, default="out.v")
        opt = parser.parse_args()
        return opt

    opt = parse_cl()
    module = Module(opt.clock)
    module.read_verilog(opt.src)
    module.construct_circuit_graph()
    module.circuit_graph.print_vertices_and_edges()
    module.print_stats()
    module.check_dangling_nets()
    module.remove_dangling_nets()
    module.write_verilog(opt.dest)

