#!/usr/bin/env python3

# Copyright (c) 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Authors:
# - Cedric Hirschi <cehirschi@student.ethz.ch>
#
# Automatically modify SystemVerilog ROM file with new data and size.
# 
# This script takes a hex file as input, processes it, and directly modifies
# the SystemVerilog ROM module by:
# 1. Updating the size parameter to match the new data size
# 2. Replacing the static ROM data array
# 
# Usage:
#     python gen_bootrom.py --help

import sys
import re
import argparse
from pathlib import Path
from typing import Tuple, List


def convert_hex_file(filename: str, max_rom_size_bytes: int = None) -> Tuple[int, bytes]:
    """
    Convert hex file to bytes format.
    
    Args:
        filename: Input hex file path
        max_rom_size_bytes: Maximum ROM size in bytes (None for no limit)
        
    Returns:
        Tuple of (actual_size_bytes, data_bytes)
    """
    current_address = None
    result = bytearray()
    
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
                
            if line.startswith('@'):
                # Parse address line
                parsed_address = int(line[1:], 16)
                print(f"  Parsed address: 0x{parsed_address:08X}")
                
                if current_address is not None and parsed_address != current_address:
                    # Pad with zeros if address jumps
                    padding_size = parsed_address - current_address
                    print(f"  Padding data from 0x{current_address:08X} to 0x{parsed_address:08X} ({padding_size} bytes)")
                    result += b'\x00' * padding_size
                    
                current_address = parsed_address
            else:
                # Convert hex data line to bytes
                try:
                    data = bytes.fromhex(line)
                    result += data
                    if current_address is not None:
                        current_address += len(data)
                except ValueError as e:
                    print(f"  Warning: Skipping invalid hex line: {line}")
                    continue

    actual_size = len(result)
    
    # Check size limit
    if max_rom_size_bytes and actual_size > max_rom_size_bytes:
        raise ValueError(f"Data size {actual_size} bytes exceeds ROM size of {max_rom_size_bytes} bytes.")
    
    return actual_size, bytes(result)


def bytes_to_sv_array(data: bytes) -> List[str]:
    """
    Convert bytes to SystemVerilog 32-bit word array format.
    
    Args:
        data: Input bytes
        
    Returns:
        List of SystemVerilog formatted hex strings
    """
    words = []
    
    # Process data in 4-byte chunks (32-bit words)
    for i in range(0, len(data), 4):
        word_bytes = data[i:i+4]
        
        # Pad incomplete words with zeros
        if len(word_bytes) < 4:
            word_bytes += b'\x00' * (4 - len(word_bytes))
        
        # Convert to little-endian 32-bit word
        word_value = int.from_bytes(word_bytes, byteorder='little')
        words.append(f"32'h{word_value:08X}")
    
    return words


def modify_systemverilog_rom(sv_content: str, new_size_bytes: int, rom_data_words: List[str]) -> str:
    """
    Modify SystemVerilog ROM content with new size and data.
    
    Args:
        sv_content: Original SystemVerilog file content
        new_size_bytes: New ROM size in bytes
        rom_data_words: List of formatted 32-bit hex words
        
    Returns:
        Modified SystemVerilog content
    """
    # Update SizeBytes parameter
    size_pattern = r"(parameter\s+int\s+SizeBytes\s*=\s*)'h[0-9A-Fa-f]+"
    new_size_hex = f"'h{new_size_bytes:04X}"
    
    sv_content = re.sub(size_pattern, rf"\1{new_size_hex}", sv_content)
    
    # Update ROM data array
    # Find the ROM data section between START and END markers
    rom_data_pattern = r"(// --- ROM STATIC DATA START ---\s*\n)(.*?)(\n\s*// --- ROM STATIC DATA END ---)"
    
    # Create new ROM data string
    if len(rom_data_words) == 0:
        new_rom_data = "    32'h0000_0000"
    else:
        # Format with proper indentation and commas, 4 words per line
        formatted_words = []
        for i in range(0, len(rom_data_words), 4):
            line_words = rom_data_words[i:i+4]
            line_parts = []
            for j, word in enumerate(line_words):
                global_idx = i + j
                if global_idx == len(rom_data_words) - 1:
                    # Last word overall, no comma
                    line_parts.append(word)
                else:
                    line_parts.append(word + ",")
            line = "    " + " ".join(line_parts) + f" // 0x{i:04X} - 0x{i + len(line_words) - 1:04X}"
            formatted_words.append(line)
        # Join all lines into a single string
        new_rom_data = "\n".join(formatted_words)
    
    # Replace the ROM data section
    def replace_rom_data(match):
        return match.group(1) + new_rom_data + match.group(3)
    
    sv_content = re.sub(rom_data_pattern, replace_rom_data, sv_content, flags=re.DOTALL)
    
    return sv_content


def main():
    parser = argparse.ArgumentParser(description="Modify SystemVerilog ROM file with new hex data.")
    parser.add_argument("--input_hex", type=str, help="Input hex file", default="build/bootrom.hex")
    parser.add_argument("--input_sv", type=str, help="Input SystemVerilog ROM file", default="../../rtl/bootrom/bootrom.sv.template")
    parser.add_argument("--size_bytes", type=int, help="ROM size in bytes (default: 4096)", default=4096)
    parser.add_argument("--output_sv", type=str, help="Output SystemVerilog file", default="../../rtl/bootrom/bootrom.sv")
    
    
    args = parser.parse_args()
    
    try:
        # Read and convert hex file
        print(f"Reading hex file: {args.input_hex}")
        actual_size, data = convert_hex_file(args.input_hex, args.size_bytes)
        print(f"Hex file contains {actual_size} bytes ({actual_size // 4} words)")
        
        # Convert to SystemVerilog format
        rom_words = bytes_to_sv_array(data)
        
        # Calculate padded size (round up to next 4-byte boundary)
        padded_size = ((actual_size + 3) // 4) * 4

        # Pad size to match requested size
        if padded_size < args.size_bytes:
            padding_size = args.size_bytes - padded_size
            print(f"Padding ROM with {padding_size} bytes of zeros to match requested size {args.size_bytes} bytes")
            rom_words += ['32\'h00000000'] * (padding_size // 4)
            padded_size = args.size_bytes
        elif padded_size > args.size_bytes:
            raise ValueError(f"Data size {padded_size} bytes exceeds requested ROM size of {args.size_bytes} bytes.")
        elif padded_size == 0:
            raise ValueError("No data found in hex file, cannot create ROM.")
        elif padded_size % 4 != 0:
            raise ValueError(f"Data size {padded_size} bytes is not a multiple of 4, cannot create ROM.")
        
        # Read original SystemVerilog file
        print(f"Reading SystemVerilog file: {args.input_sv}")
        with open(args.input_sv, 'r') as f:
            sv_content = f.read()
        
        # Modify SystemVerilog content
        # print(f"Updating ROM with {len(rom_words)} words, size = {padded_size} bytes")
        modified_content = modify_systemverilog_rom(sv_content, padded_size, rom_words)
        
        # Write output file
        # print(f"Writing modified SystemVerilog file: {args.output_sv}")
        with open(args.output_sv, 'w') as f:
            f.write(modified_content)
        
        print(f"Successfully updated ROM:")
        print(f"  - Size: {padded_size} bytes ({len(rom_words)} words)")
        print(f"  - Data: {len(rom_words)} entries")
        print(f"  - Output: {args.output_sv}")
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()