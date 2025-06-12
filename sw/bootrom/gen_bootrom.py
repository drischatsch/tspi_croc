"""
Generate a hex file for the Boot ROM from a hex file.

The hex file is converted to bytes, padded to the ROM size, and written
to a hex file compatible with the SystemVerilog $readmemh function.
"""
import sys
from pathlib import Path
import argparse


# Default values
output_filename = Path(__file__).parent / "bootrom.hex"
rom_size_words = 1000


def write_hex(filename: str, data: bytes) -> None:
    # Write bytes to a hex file
    # Each line in the hex file will contain 4 bytes (32 bits) in hexadecimal format
    # The $readmemh function in SystemVerilog expects the data to be in this format
    with open(filename, 'w') as f:
        for word in range(0, len(data), 4):
            # Convert each 4 bytes to a hex string
            word_bytes = data[word:word + 4]

            # Swap the byte order for little-endian format
            word_bytes = word_bytes[::-1]

            hex_string = ''.join(f'{byte:02X}' for byte in word_bytes)
            # Write the hex string to the file
            f.write(f"{hex_string}\n")

def convert_hex_file(filename: str, rom_size_bytes: int) -> bytes:
    current_address = None
    result = bytearray()
    with open(filename, 'r') as f:
        for line in f:
            if line.startswith('@'):
                parsed_address = int(line[1:], 16)  # Address is in the first 4 characters after '@'
                print(f"Parsed address: 0x{parsed_address:08X}")
                if current_address is not None and parsed_address != current_address:
                    # If the address changes, pad the data with 0x00
                    print(f"Padding data from 0x{current_address:08X} to 0x{parsed_address:08X}")
                    result += b'\x00' * (parsed_address - current_address)
                current_address = parsed_address
            else:
                # Convert the hex string to bytes and append to the result
                data = bytes.fromhex(line.strip())
                result += data
                current_address += len(data)

    input_size = len(result)

    # Check if the input size exceeds the ROM size
    if input_size > rom_size_bytes:
        raise ValueError(f"Data {input_size} bytes exceeds ROM size of {rom_size_bytes} bytes.")

    # Pad to rom size with 0x00
    result += b'\x00' * (rom_size_bytes - input_size)

    return input_size, result

if __name__ == "__main__":
    # Check if the script is run with the correct arguments
    parser = argparse.ArgumentParser(description="Generate a hex file for the Boot ROM.")
    parser.add_argument("input", type=str, help="Input hex file name")
    parser.add_argument("-o", "--output", type=str, default=output_filename, help="Output hex file name")
    parser.add_argument("-r", "--rom_size", type=int, default=rom_size_words, help="ROM size in words (4 bytes each)")
    args = parser.parse_args()

    rom_size_bytes = args.rom_size * 4

    # Convert the string to bytes
    data_size, data = convert_hex_file(args.input, rom_size_bytes)
    # Write the bytes to a hex file
    write_hex(args.output, data)
    print(f"User ROM file '{args.output}' created with size {data_size} bytes ({data_size / 4} words) from '{args.input}'.")