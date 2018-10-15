'''
    File name      : change_cell_names.py
    Author         : Jinwook Jung
    Created on     : Sun 06 Aug 2017 10:19:49 PM KST
    Last modified  : 2017-08-06 23:54:14
    Description    : Change cell names of ICCAD'14 TDP contest Verilogs.
'''

from time import gmtime, strftime
import sys, re, os


def extract_pin_and_net(token):
    """ token should be .PIN(NET), or .PIN(NET) """

    # replace ,.() with blank
    for c in ('.', ',', '(', ')'):
        token = token.replace(c, ' ')

    token = token.strip().split()
    pin, net = token[0], token[1]

    return pin, net


def change_cell_name(token):
    """ token should be <FUNCTION>_<SIZE> """

    offset = token.find('_')

    if offset == -1:
        return token    # FIXME

    function = token[:offset]
    function_dict = {
        'INV'   : 'in01',
        'NAND2' : 'na02',
        'NAND3' : 'na03',
        'NAND4' : 'na04',
        'NOR2'  : 'no02',
        'NOR3'  : 'no03',
        'NOR4'  : 'no04',
        'TIEH'  : 'vcc',
        'TIEL'  : 'vss',
        'AOI21' : 'ao12',
        'AOI22' : 'ao22',
        'OAI21' : 'oa12',
        'OAI22' : 'oa22'
    }

    size = token[offset+1:]
    size_dict = {1:1, 2:2, 4:4, 8:8, 16:20, 32:80}

    try:
        function = function_dict[function]
    except KeyError:
        sys.stderr.write("(W) Cannot change cell name %s" % (function))
        function = function

    if size.startswith('X'):
        size = "s%02d" % (size_dict[int(size[1:])])
    elif size.startswith('Y'):
        size = "m%02d" % (size_dict[int(size[1:])])
    elif size.startswith('Z'):
        size = "f%02d" % (siez_dict[int(size[1:])])
    else:   # it must be a block
        size = size

    if function.startswith('block'):
        return token

    if function in('vcc', 'vss'):
        return function

    return function + size


def change_pin_name(pin_string, gate_type):
    pins = list()

    if gate_type == 'dff':
        for pin in pin_string:    # silly code..
            p, n = extract_pin_and_net(pin)
            if p.upper() == 'D':
                pins.append(".d(%s)" % (n))
            elif p.upper() == 'Q':
                pins.append(".o(%s)" % (n))
            elif p.upper() == 'CK':
                pins.append(".ck(%s)" % (n))
            else:
                pins.append(pin.strip(','))

    elif gate_type[:4] in ('ao12', 'oa12'):
        for pin in pin_string:    # silly code..
            p, n = extract_pin_and_net(pin)
            if p.upper() == 'A':
                pins.append(".a(%s)" % (n))
            elif p.upper() == 'B1':
                pins.append(".b(%s)" % (n))
            elif p.upper() == 'B2':
                pins.append(".c(%s)" % (n))
            elif p.upper() in ('ZN', 'Z'):
                pins.append(".o(%s)" % (n))
            else:
                pins.append(pin.strip(','))

    elif gate_type[:4] in ('ao22', 'oa22'):
        for pin in pin_string:    # silly code..
            p, n = extract_pin_and_net(pin)
            if p.upper() == 'A1':
                pins.append(".a(%s)" % (n))
            elif p.upper() == 'A2':
                pins.append(".b(%s)" % (n))
            elif p.upper() == 'B1':
                pins.append(".c(%s)" % (n))
            elif p.upper() == 'B2':
                pins.append(".d(%s)" % (n))
            elif p.upper() in ('ZN', 'Z'):
                pins.append(".o(%s)" % (n))
            else:
                pins.append(pin.strip(','))

    else:
        for pin in pin_string:    # silly code..
            p, n = extract_pin_and_net(pin)
            if p.upper() == 'A':
                pins.append(".a(%s)" % (n))
            elif p.upper() == 'A1':
                pins.append(".a(%s)" % (n))
            elif p.upper() == 'A2':
                pins.append(".b(%s)" % (n))
            elif p.upper() == 'A3':
                pins.append(".c(%s)" % (n))
            elif p.upper() == 'A4':
                pins.append(".d(%s)" % (n))
            elif p.upper() in ('ZN', 'Z'):
                pins.append(".o(%s)" % (n))
            else:
                pins.append(pin.strip(','))

    return pins


def change_verilog(src, dest):
    with open(src, 'r') as f:
        lines = [line.rstrip() for line in f]

    with open(dest, 'w') as f:
        for line in lines:
            if line.startswith('//'):
                f.write(line + '\n')
                continue

            tokens = line.split()

            if len(tokens) < 1:
                f.write(line + '\n')

            # remove clock buffer
            elif tokens[0].startswith('CLKBUF'):
                continue

            # Change dff cells
            elif tokens[0].startswith('DFF'):
                #  0   1   2    3       4       5       6
                # DFF INST ( .D(net), .Q(net), .CK(net) );
                pin_string = tokens[3:-1]
                pins = change_pin_name(pin_string, 'dff')

                f.write("ms00f80 %s ( " % (tokens[1]))
                f.write("%s );\n" % (', '.join(pins)))

            # Cell instantiations
            elif len(tokens) > 4:
                cell_name = change_cell_name(tokens[0])
                instance_name = tokens[1]
                pin_string = tokens[3:-1]
                pins = change_pin_name(pin_string, cell_name)

                f.write("%s %s ( " % (cell_name, instance_name))
                f.write("%s );\n" % (', '.join(pins)))

            else:
                f.write(line + '\n')


if __name__ == '__main__':
    def parse_cl():
        import argparse
        parser = argparse.ArgumentParser(description='')
        parser.add_argument('-i', dest='src_v', required=True)
        parser.add_argument('-o', dest='dest_v', default='out.v')

        return parser.parse_args()

    opt = parse_cl()
    src = opt.src_v
    dest = opt.dest_v

    print ("Input file  : " + src)
    print ("Output file : " + dest)
    sys.stdout.flush()

    change_verilog(src, dest)

