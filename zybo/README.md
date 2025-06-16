# Croc Zybo-Z7 FPGA flow

## Getting Started

1. Replace any TODOs in configuration files with your actual paths
2. Generate the clock wizard using the Vivado GUI

## Debugging with OpenOCD and GDB

### Starting OpenOCD

Open a terminal and run:

```bash
openocd -f connect.tcl
```

### Launching GDB

In a new terminal, start GDB:

```bash
riscv64-elf-gdb helloworld.elf
target extended-remote localhost:3333  # Connect to OpenOCD server
```

### Essential GDB Commands

| Command | Action |
|---------|--------|
| `load` | Program flash/RAM |
| `break main` | Set breakpoint at main() |
| `continue` (or `c`) | Resume execution |
| `step` (or `s`) | Step into function |
| `next` (or `n`) | Step over function |
| `info registers` | View CPU registers |
| `x/10x 0x80000000` | Examine 10 words at address 0x80000000 |
| `monitor reset halt` | Reset and halt the target |