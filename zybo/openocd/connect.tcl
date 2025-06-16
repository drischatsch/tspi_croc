adapter speed 1000
adapter driver ftdi
# adapter serial 210249AEC1F4

ftdi vid_pid 0x0403 0x6014
ftdi layout_init 0x00e8 0x60eb
ftdi channel 0

transport select jtag
telnet_port disabled
tcl_port disabled
reset_config none

gdb_report_data_abort enable
gdb_report_register_access_error enable

# gdb_port 12475

bindto 0.0.0.0

set _CHIPNAME riscv
jtag newtap $_CHIPNAME cpu -irlen 5 -expected-id 0x0c0c5db3

set _TARGETNAME $_CHIPNAME.cpu
target create $_TARGETNAME riscv -chain-position $_TARGETNAME -coreid 0

gdb_report_data_abort enable
gdb_report_register_access_error enable

riscv set_reset_timeout_sec 120
riscv set_command_timeout_sec 120

riscv set_mem_access progbuf sysbus abstract

init
halt
echo "Ready for Remote Connections"

