# Croc TSPI SD-Card Flasher

## Usage

A list of removable drives can be shown with the `list_removable.sh` script.

For me, when I attached one SD card, I get:
```bash
/dev/sde          ?         usb
/dev/sdf          ?         usb
/dev/sdf1         ?         (not mounted)
```
Here, I sometimes had to use `/dev/sde`, sometimes `/dev/sdf`.

### Write an Image

You can write a raw binary image (`.bin`) to a device without a filesystem with the `write.py` script.

Examples:
```bash
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
```

The output with the provided [`helloworld.bin`](helloworld.bin) looks like this:
```bash
$ sudo python write.py helloworld.bin /dev/sde --erase
Image size: 1860 bytes (1 KiB)
Erasing 4 blocks of 512 bytes each...
Erasing complete ✔
Flashing helloworld.bin to /dev/sde...
Flashing complete ✔
```

### Read some Blocks

You can read some blocks from a device using the `read.py` script.

Examples:
```bash
# read 1 block from a block device:
sudo ./read.py /dev/sdb

# read 10 blocks from a block device:
sudo ./read.py /dev/sdb -n 10

# read 1 block from a block device with a custom block size:
sudo ./read.py /dev/sdb --block-size 4096

# read 1 block from a block device with an offset (10 blocks):
sudo ./read.py /dev/sdb --offset 10
```

### Windows

This software can only be used in Linux. On windows, WSL2 can be used but you will have to go through some more steps before using this software.

In an administrator prompt:

1. Start `vhci_hcd` module
    ```bash
    wsl sudo modprobe vhci_hcd
    ```
2. Find drive with usbipd. Note its BUSID
    ```bash
    usbidp list
    ```
3. Bind and attach drive
    ```bash
    usbidp bind --busid BUSID
    usbidp attach --wsl --busid BUSID
    ```