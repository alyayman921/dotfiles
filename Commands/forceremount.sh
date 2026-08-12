#!/bin/bash
sudo  umount -f /dev/sda1
sudo  umount -f /dev/nvme0n1p6
sudo  umount -f /dev/nvme0n1p4
sudo  mount -t ntfs-3g /dev/sda1 ~/Storage
sudo  mount -t ntfs-3g /dev/nvme0n1p6 ~/SSD
sudo  mount -t ntfs-3g /dev/nvme0n1p4 ~/Windows
 
