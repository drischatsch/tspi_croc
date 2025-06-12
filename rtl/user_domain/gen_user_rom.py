"""
Generate a hex file for the user ROM with a specific string.

The string is converted to bytes, padded to the ROM size, and written
to a hex file compatible with the SystemVerilog $readmemh function.
"""
import sys
from pathlib import Path
import argparse


# Default values
filename = Path(__file__).parent / "user_rom.hex"
string = "Dumeni&Cedric's ASIC v0.1.0"
rom_size_words = 8


def write_hex(filename: str, data: bytes) -> None:
    # Write bytes to a hex file
    # Each line in the hex file will contain 4 bytes (32 bits) in hexadecimal format
    # The $readmemh function in SystemVerilog expects the data to be in this format
    with open(filename, 'w') as f:
        for word in range(0, len(data), 4):
            data_word = data[word:word + 4][::-1]  # Reverse the byte order for little-endian format

            # Convert each 4 bytes to a hex string
            hex_string = ''.join(f'{byte:02X}' for byte in data_word)
            # Write the hex string to the file
            f.write(f"{hex_string}\n")

def convert_string(data: str, rom_size_bytes: int) -> bytes:
    # Convert the string to bytes using UTF-8 encoding
    data_converted = data.encode('utf-8')
    # Pad to rom size with 0x00
    data_converted += b'\x00' * (rom_size_bytes - len(data_converted))
    # Truncate to rom size
    data_converted = data_converted[:rom_size_bytes]
    return data_converted

if __name__ == "__main__":
    # Check if the script is run with the correct arguments
    parser = argparse.ArgumentParser(description="Generate a hex file for the user ROM.")
    parser.add_argument("-f", "--filename", type=str, default=filename, help="Output hex file name")
    parser.add_argument("-s", "--string", type=str, default=string, help="String to write to the ROM")
    parser.add_argument("-r", "--rom_size", type=int, default=rom_size_words, help="ROM size in words (4 bytes each)")
    args = parser.parse_args()

    rom_size_bytes = args.rom_size * 4

    # Convert the string to bytes
    data = convert_string(args.string, rom_size_bytes)
    # Write the bytes to a hex file
    write_hex(args.filename, data)
    print(f"User ROM file '{args.filename}' created with size {rom_size_bytes} bytes ({args.rom_size} words).")