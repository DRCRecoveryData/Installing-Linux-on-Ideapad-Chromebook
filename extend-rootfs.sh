#!/bin/bash

echo ""
echo "Resizing root filesystem..."
echo ""

# Set known values for your system
ROOTDEVICE="mmcblk0p3"
ROOTDEVICEBASE="mmcblk0"
ROOTDEVICEPARTNUMBER="3"
ROOTFSTYPE="ext4"

# Get the current start sector of the root partition
ROOTPARTITIONSTART=$(sfdisk -d /dev/$ROOTDEVICEBASE | grep $ROOTDEVICE | awk '{print $4}' | sed 's/,//g')

# Get the current PARTUUID
ROOTPARTUUID=$(blkid | grep "/dev/$ROOTDEVICE" | sed 's/.*PARTUUID="//;s/".*//')

# Confirm values before proceeding
echo "Device: /dev/$ROOTDEVICE"
echo "Base: /dev/$ROOTDEVICEBASE"
echo "Partition #: $ROOTDEVICEPARTNUMBER"
echo "Start sector: $ROOTPARTITIONSTART"
echo "UUID: $ROOTPARTUUID"
echo "Filesystem: $ROOTFSTYPE"
echo ""

read -p "Proceed to resize the partition? [Y/n] " confirm
confirm=${confirm:-Y}  # Default to 'Y' if no input is given
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

# Recreate the partition using fdisk for GPT
fdisk /dev/$ROOTDEVICEBASE << EOF
d
$ROOTDEVICEPARTNUMBER
n
$ROOTDEVICEPARTNUMBER
$ROOTPARTITIONSTART

x
u
$ROOTDEVICEPARTNUMBER
$ROOTPARTUUID
r
p
w
EOF

echo ""
echo "Partition updated. Informing kernel..."
partprobe /dev/$ROOTDEVICEBASE

echo ""
echo "Resizing filesystem..."
if [ "$ROOTFSTYPE" = "btrfs" ]; then
  btrfs filesystem resize max /
else
  resize2fs /dev/$ROOTDEVICE
fi

echo ""
echo "Done."
