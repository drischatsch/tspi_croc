#!/usr/bin/env python3

# Copyright (c) 2024 ETH Zurich.
#
# Authors:
# - Cedric Hirschi <cehirschi@student.ethz.ch>
#
# Write a raw binary to a device (e.g. SD card) without a filesystem.

import os, sys, argparse
import textwrap

def flash_raw(image: str, device: str, block_size: int = 512, offset: int = 0, erase: bool = True, verify: bool = False):
    # 1) sanity check
    if os.geteuid() != 0:
        sys.exit("ERROR: must run as root (or via sudo)")
    if not os.path.exists(image):
        sys.exit(f"ERROR: image '{image}' not found")
    if not os.path.exists(device):
        sys.exit(f"ERROR: device '{device}' not found")

    # 2) unmount any mounted partitions
    #    (on Linux you could do `os.system(f"umount {device}?*")`)
    #    but simplest is: make sure they're unmounted beforehand.

    if erase:
        # 3) open and erase blocks
        with open(image, 'rb') as img, open(device, 'wb') as dev:
            total = os.path.getsize(image)

            print(f"Image size: {total} bytes ({total // 1024} KiB)")

            total_blocks = total // block_size
            if total % block_size != 0:
                total_blocks += 1

            # Go to offset
            dev.seek(offset * block_size)

            # Erase the device first (optional, but recommended)
            print(f"Erasing {total_blocks} blocks of {block_size} bytes each...")
            for _ in range(total_blocks):
                dev.write(b'\x00' * block_size)
                print(f"\rErased {_+1}/{total_blocks} blocks...", end='', flush=True)
            print("\rErasing complete ✔     ")

    # 4) write the image to the device
    with open(image, 'rb') as img, open(device, 'wb') as dev:
        total = os.path.getsize(image)
        print(f"Flashing {image} to {device}...")

        # Go to offset
        dev.seek(offset * block_size)

        written = 0
        while True:
            chunk = img.read(block_size)
            if not chunk:
                break
            dev.write(chunk)
            written += len(chunk)
            # simple progress
            print(f"\rWritten {written*100/total:5.1f}%...", end='', flush=True)
        print("\rFlashing complete ✔     ")

    # 4) force write‐back all buffers to the card
    os.sync()

    if verify:
        # 5) verify written data
        with open(image, 'rb') as img, open(device, 'rb') as dev:
            img.seek(offset * block_size)
            dev.seek(offset * block_size)

            total = os.path.getsize(image)
            total_blocks = total // block_size
            if total % block_size != 0:
                total_blocks += 1

            print(f"Verifying {total_blocks} blocks of {block_size} bytes each...")
            verified = 0
            while True:
                img_chunk = img.read(block_size)
                dev_chunk = dev.read(block_size)

                if not img_chunk and not dev_chunk:
                    break

                if len(dev_chunk) > len(img_chunk):
                    dev_chunk = dev_chunk[:len(img_chunk)]

                if img_chunk != dev_chunk:
                    sys.exit(f"\rERROR: verification failed! Data mismatch detected at offset 0x{verified * block_size + offset * block_size:08X}\n"
                             f"Expected:\n\t{img_chunk.hex()}\n"
                             f"Got:\n\t{dev_chunk.hex()}")

                verified += 1
                print(f"\rVerified {verified*100/total_blocks:5.1f}%...", end='', flush=True)
                if verified == total_blocks:
                    break

            print("\rVerification complete ✔     ")


if __name__ == "__main__":
    p = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent("""
            Write a raw binary to a device (e.g. SD card) without a filesystem.

            Examples:
              # flash a raw image to a block device:
              sudo ./write.py /path/to/image.bin /dev/sdb
                                    
              # flash a raw image to a block device with custom block size:
              sudo ./write.py /path/to/image.bin /dev/sdb --block-size 4096
                                    
              # erase the device before flashing:
              sudo ./write.py /path/to/image.bin /dev/sdb --erase
                                    
              # flash a raw image to a block device with an offset (10 blocks):
              sudo ./write.py /path/to/image.bin /dev/sdb --offset 10
                                    
              # flash a raw image and verify after writing:
              sudo ./write.py /path/to/image.bin /dev/sdb --verify
        """)
    )
    p.add_argument('image', help='path to the raw image file')
    p.add_argument('device', help='path to the block device (e.g. /dev/sdb)')
    p.add_argument('--block-size', '-b', type=int, default=512, help='bytes per block (default: 512)')
    p.add_argument('--offset', '-o', type=int, default=0, help='block offset to start writing (default: 0)')
    p.add_argument('--erase', '-e', action='store_true', help='erase the device before flashing')
    p.add_argument('--verify', '-v', action='store_true', help='verify written data after flashing')

    flash_raw(**vars(p.parse_args()))
