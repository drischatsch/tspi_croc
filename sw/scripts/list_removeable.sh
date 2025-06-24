# Copyright (c) 2024 ETH Zurich.
#
# Authors:
# - Cedric Hirschi <cehirschi@student.ethz.ch>
#
# List all removable block devices and their mountpoints.

lsblk -pnro NAME,RM,MOUNTPOINT,TRAN |
awk '
  # NAME    RM  MOUNTPOINT    TRAN
  $2 == 1 {                   # RM==1 → removable
    printf "%-16s  %-8s  %s\n", $1, ($4==""?"?":$4), ($3==""?"(not mounted)":$3)
  }
'