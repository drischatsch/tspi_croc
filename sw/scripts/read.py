#!/usr/bin/env python3

# Copyright (c) 2024 ETH Zurich.
#
# Authors:
# - Cedric Hirschi <cehirschi@student.ethz.ch>
#
# Read raw blocks from a block device (e.g. SD card) without a filesystem.

import os, sys, argparse
import textwrap

def hex_dump(data: bytes, offset: int = 0, width: int = 16):
    for i in range(0, len(data), width):
        chunk = data[i:i+width]
        hex_bytes = ' '.join(f'{b:02X}' for b in chunk)
        ascii_bytes = ''.join((chr(b) if 32 <= b < 127 else '.') for b in chunk)
        print(f'{i+offset:08X}  {hex_bytes:<{width*3}}  |{ascii_bytes}|')

def read_blocks(device: str, offset: int = 0, count: int = 1, block_size: int = 512, out: str = None):
    # must be root
    if hasattr(os, 'geteuid'):
        if os.geteuid() != 0:
            sys.exit("ERROR: this script must be run as root (sudo).")

    if not os.path.exists(device):
        sys.exit(f"ERROR: device '{device}' not found.")

    byte_offset = offset * block_size
    total_bytes = count * block_size

    try:
        with open(device, 'rb') as dev:
            dev.seek(byte_offset)
            data = dev.read(total_bytes)
            if len(data) < total_bytes:
                print(f"WARNING: only read {len(data)} of {total_bytes} bytes.", file=sys.stderr)

    except PermissionError as e:
        sys.exit(f"ERROR: permission denied: {e}")
    except OSError as e:
        sys.exit(f"ERROR: I/O error: {e}")

    if out:
        try:
            with open(out, 'wb') as fout:
                fout.write(data)
            print(f"Dumped {len(data)} bytes to '{out}'.")
        except OSError as e:
            sys.exit(f"ERROR writing output file: {e}")
    else:
        hex_dump(data, offset=byte_offset)

if __name__ == '__main__':
    p = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent("""
            Read raw blocks from a block device (e.g. SD card) without a filesystem.

            Examples:
              # read 4 blocks of 512 B each from block offset 0 and hex-dump:
              sudo ./read.py --device /dev/sdb --count 4

              # dump 128 blocks (64 KiB) at offset 2048 to a file:
              sudo ./read.py --device /dev/sdb --offset 2048 \\
                                       --count 128 --block-size 512 --out dump.bin
        """))
    p.add_argument('device', help='path to block device (e.g. /dev/sdb)')
    p.add_argument('--offset',   '-o', type=int, default=0,
                   help='block offset to start reading (default: 0)')
    p.add_argument('--count',    '-n', type=int, default=1,
                   help='number of blocks to read (default: 1)')
    p.add_argument('--block-size','-b', type=int, default=512,
                   help='bytes per block (default: 512)')
    p.add_argument('--out',      '-f', default=None,
                   help='optional output file (raw); if omitted, data is hex-dumped')
    
    read_blocks(**vars(p.parse_args()))