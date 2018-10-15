'''
    File name      : download_tau17_benchmarks.py
    Author         : Jinwook Jung
    Created on     : Sat 05 Aug 2017 02:35:14 PM KST
    Last modified  : 2017-08-06 20:38:19
    Description    : Download TAU'17 timing contest benchmarks. Use Python 3.
'''
from __future__ import print_function
import requests, subprocess, os, sys


def download_from_google_site(url, dest):
    response = requests.get(url, stream=True)
    print("%.3f MB" % (len(response.content) / 1024.0 / 1024), flush=True)
    save_response_content(response, dest)


# Source: https://stackoverflow.com/questions/38511444/python-download-files-from-google-drive-using-url
def download_from_google_drive(id, dest):
    url = "https://docs.google.com/uc?export=download"
    session = requests.Session()
    response = session.get(url, params = {'id':id, 'usp':'sharing'}, stream = True)

    token = get_confirm_token(response)
    if token:
        params = {'id':id, 'confirm':token}
        response = session.get(url, params = params, stream = True)

    print("%.3f MB" % (len(response.content) / 1024.0 / 1024), flush=True)
    save_response_content(response, dest)


def get_confirm_token(response):
    for key, value in response.cookies.items():
        if key.startswith('download_warning'):
            return value
    return None


def save_response_content(response, dest):
    CHUNK_SIZE = 2**23

    with open(dest, "wb") as f:
        for chunk in response.iter_content(CHUNK_SIZE):
            if chunk: # filter out keep-alive new chunks
                f.write(chunk)


def convert_verilog_to_blif(verilog, blif):
    from verilog_to_blif_converter_tau17 import BlifConverter
    blif_converter = BlifConverter()
    blif_converter.read_verilog(verilog)
    blif_converter.write_blif(blif)


def map_latches(verilog):
    from latch_mapper import  Latch, LatchMapper
    latch_cell = "ms00f80"
    clock_port = "clk"
    mapper = LatchMapper(clock_port, latch_cell)
    mapper.read_verilog(verilog)
    mapper.map_latches(verilog)


def change_iccad_cell_names(src, dest):
    import change_cell_names
    change_cell_names.change_verilog(src, dest)


def create_sdc(bench_name, timing, sdc):
    import convert_timing_to_sdc
    convert_timing_to_sdc.convert(bench_name, timing, sdc, clock_port="clk")

#tau17_benchmarks = ( \
#    ("usb_funct",             "https://sites.google.com/site/taucontest2017/resources/usb_funct.tar.gz?attredirects=0"),
#    ("crc32d16N",             "https://sites.google.com/site/taucontest2017/resources/crc32d16N.tar.gz?attredirects=0"),
#    ("ac97_ctrl",             "https://sites.google.com/site/taucontest2017/resources/ac97_ctrl.tar.gz?attredirects=0"),
#    ("aes_core",              "https://sites.google.com/site/taucontest2017/resources/aes_core.tar.gz?attredirects=0"),
#    ("des_perf",              "https://sites.google.com/site/taucontest2017/resources/des_perf.tar.gz?attredirects=0"),
#    ("pci_bridge32",          "https://sites.google.com/site/taucontest2017/resources/pci_bridge32.tar.gz?attredirects=0"),
#    ("systemcaes",            "https://sites.google.com/site/taucontest2017/resources/systemcaes.tar.gz?attredirects=0"),
#    ("systemcdes",            "https://sites.google.com/site/taucontest2017/resources/systemcdes.tar.gz?attredirects=0"),
#    ("tv80",                  "https://sites.google.com/site/taucontest2017/resources/tv80.tar.gz?attredirects=0"),
#    ("vga_lcd",               "https://drive.google.com/file/d/0B7cpBRIFsGtrM3NJblI2ZkE3Qlk/view?usp=sharing"),
#    ("wb_dma",                "https://sites.google.com/site/taucontest2017/resources/wb_dma.tar.gz?attredirects=0"),
#    ("pci_bridge32",          "https://sites.google.com/site/taucontest2017/resources/pci_bridge32.tar.gz?attredirects=0"),
#    ("cordic_ispd",           "https://sites.google.com/site/taucontest2017/resources/cordic_ispd.tar.gz?attredirects=0"),
#    ("des_perf_ispd",         "https://drive.google.com/file/d/0B7cpBRIFsGtrQ1cwc1pNYVNEbmc/view?usp=sharing"),
#    ("edit_dist_ispd",        "https://drive.google.com/file/d/0B7cpBRIFsGtrbklXdHUweEpUdkk/view?usp=sharing"),
#    ("edit_dist2_ispd",       "https://drive.google.com/file/d/0B7cpBRIFsGtrUkl6YTVKcWNnYkU/view?usp=sharing"),
#    ("matrix_mult_ispd",      "https://drive.google.com/file/d/0B7cpBRIFsGtrVEtlNXI3aGpYOWs/view?usp=sharing"),
#    ("cordic2_ispd",          "https://sites.google.com/site/taucontest2017/resources/cordic2_ispd.tar.gz?attredirects=0"),
#    ("fft_ispd",              "https://sites.google.com/site/taucontest2017/resources/fft_ispd.tar.gz?attredirects=0"),
#    ("usb_phy_ispd",          "https://sites.google.com/site/taucontest2017/resources/usb_phy_ispd.tar.gz?attredirects=0"),
#    ("b19_iccad",             "https://drive.google.com/open?id=0B7cpBRIFsGtrcW1Nd2FybzZiRHc"),
#    ("leon2_iccad",           "https://drive.google.com/open?id=0B7cpBRIFsGtrVVo4eDk5RjNIamM"),
#    ("leon3mp_iccad",         "https://drive.google.com/open?id=0B7cpBRIFsGtrQlhPdHZ3bGdKM0E"),
#    ("mgc_edit_dist_iccad",   "https://drive.google.com/open?id=0B7cpBRIFsGtrbmVIa3laMk9udHc"),
#    ("mgc_matrix_mult_iccad", "https://drive.google.com/open?id=0B7cpBRIFsGtrYWFodFVXejJVUXc"),
#    ("netcard_iccad",         "https://drive.google.com/open?id=0B7cpBRIFsGtrbGxGQzUtWlBPb1k"),
#    ("vga_lcd_iccad",         "https://drive.google.com/open?id=0B7cpBRIFsGtrdmFpUjNaZVVZTDA"),
#)

tau17_benchmarks = ( \
    ("usb_funct",             "https://sites.google.com/site/taucontest2017/resources/usb_funct.tar.gz?attredirects=0"),
    ("ac97_ctrl",             "https://sites.google.com/site/taucontest2017/resources/ac97_ctrl.tar.gz?attredirects=0"),
)



def download_benchmarks(benchmarks):
    for bench_name, url in benchmarks:
        tar_name = bench_name + ".tar.gz"
        print("Downloading %s ..." % tar_name, end=' ', flush=True)
        if url.startswith("https://sites."):
            url = url.split('?')[0]
            download_from_google_site(url, tar_name)

        elif url.startswith("https://drive.google.com/file/d/"):
            file_id = url.split('/')[5]
            download_from_google_drive(file_id, tar_name)

        elif url.startswith("https://drive.google.com/open"):
            file_id = url.split('=')[1]
            download_from_google_drive(file_id, tar_name)

        cmd = "tar xvfz {}".format(tar_name)
        run_shell_cmd(cmd)

        if os.path.isfile("{0}/{0}.v.gz".format(bench_name)):
            cmd = "gunzip {0}/{0}.v.gz".format(bench_name)
            run_shell_cmd(cmd)

        cmd = "mv {0}/{0}.v {0}/{0}.orig.v".format(bench_name)
        run_shell_cmd(cmd)

        cmd = "rm {}".format(tar_name)
        run_shell_cmd(cmd)


def remap_benchmarks(benchmarks):
    for bench_name, url in benchmarks:
        print("Converting the Verilog of %s into a BLIF ..." % bench_name, flush=True)
        blif    = "{0}/{0}.orig.blif".format(bench_name)
        verilog = "{0}/{0}.orig.v".format(bench_name)

        # print("Run ABC to remap.")
        if bench_name == "crc32d16N":
            src_lib = crc_lib

        elif bench_name.endswith("ispd"):
            src_lib = open_design_flow_lib

        elif bench_name.endswith("iccad"):
            src_lib = open_design_flow_lib
            dest = "{0}/{0}.change_cell_name.v".format(bench_name)
            change_iccad_cell_names(verilog, dest)
            verilog = dest

        else:
            src_lib = nangate_lib

        convert_verilog_to_blif(verilog, blif)

        verilog = "{0}/{0}_remapped.v".format(bench_name)
        cmd = "{} -c \"".format(abc_path)
        cmd += "read {0}; read -m {1}; unmap;".format(src_lib, blif)
        cmd += " read {0}; map; write_verilog {1};".format(open_design_flow_lib, verilog)
        cmd += " quit\""
        run_shell_cmd(cmd)

        # print("Map latches.")
        map_latches(verilog)

        # print("Create SDC.")
        timing = "{0}/{0}.timing".format(bench_name)
        sdc = "{0}/{0}.sdc".format(bench_name)
        create_sdc(bench_name, timing, sdc)


def remove_dangling_wires(benchmarks):
    import verilog_parser

    for bench_name, url in benchmarks:
        verilog = "{0}/{0}_remapped.v".format(bench_name)
        print("Removing dangling wires of %s ..." % (bench_name), flush=True)
        module = verilog_parser.Module()
        module.read_verilog(verilog)
        module.construct_circuit_graph()
        module.remove_dangling_nets()

        verilog = "{0}/{0}.v".format(bench_name)
        module.write_verilog(verilog)

def setup_benchmark_directories(benchmarks, remove_unnecessary_files=False):
    for bench_name, url in benchmarks:
        print("Setting up benchmark directory for %s ..." % bench_name, flush=True)
        cmd = "rm {0}/*.lib".format(bench_name)
        run_shell_cmd(cmd)

        if opt.remove_unnecessary_files:
            cmd = "rm {0}/*.spef*; rm {0}/*.orig.*;" \
                  "rm {0}/*.tau2016; rm {0}/*.change_cell_name.v" \
                  .format(bench_name)
            run_shell_cmd(cmd)

        cmd = "mv {0} ../{0}".format(bench_name)
        run_shell_cmd(cmd)

        cmd = "cd ../{0}; ln -s ../libs/open_design_flow_Late.lib" \
              " {0}_Late.lib".format(bench_name)
        run_shell_cmd(cmd)

        cmd = "cd ../{0}; ln -s ../libs/open_design_flow_Early.lib" \
              " {0}_Early.lib".format(bench_name)
        run_shell_cmd(cmd)

        cmd = "cd ../{0}; ln -s ../libs/open_design_flow.lef" \
              " {0}.lef".format(bench_name)
        run_shell_cmd(cmd)


if __name__ == "__main__":
    def parse_cl():
        import argparse
        parser = argparse.ArgumentParser(description='')
        parser.add_argument('--remove_unnecessary_files',
                            action="store_true", default=False)
        return parser.parse_args()

    opt = parse_cl()

    def run_shell_cmd(cmd):
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, shell=True)
        p.communicate()
        p.wait()

    sys.path.append(os.path.abspath("../../utils"))

    abc_path = os.path.abspath("../../bin/abc")
    nangate_lib = "../libs/NangateOpenCellLibrary_typical.lib"
    crc_lib = "../libs/crc.lib"
    open_design_flow_lib = "../libs/open_design_flow_Typical.lib"

    print("Start downloading TAU'17 contest benchmarks", flush=True)
    download_benchmarks(tau17_benchmarks)

    print("Remap the benchmarks to the library of OpenDesign Flow Database.", flush=True)
    remap_benchmarks(tau17_benchmarks)

    print("Remove dangling wires.", flush=True)
    remove_dangling_wires(tau17_benchmarks)

    print("Set up the benchmark directories.", flush=True)
    setup_benchmark_directories(tau17_benchmarks, opt.remove_unnecessary_files)

    print("Completed!", flush=True)

