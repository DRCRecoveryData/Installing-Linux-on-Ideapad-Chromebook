#!/bin/bash

echo ""
echo "Attempting to complete root filesystem resize..."
echo "This step ensures the ext4 filesystem fills the expanded partition."
echo ""

# Set known values (as per your initial script)
ROOTDEVICE="mmcblk0p3"
ROOTFSTYPE="ext4"

# Step 1: Inform the kernel again (just in case the previous one failed silently)
echo "Informing kernel of partition changes on /dev/mmcblk0..."
partprobe /dev/mmcblk0

# Step 2: Resize the filesystem to fill the available space
echo "Resizing $ROOTFSTYPE filesystem on /dev/$ROOTDEVICE..."
if [ "$ROOTFSTYPE" = "btrfs" ]; then
    btrfs filesystem resize max /
else
    # The command without a size parameter expands to the max size of the partition
    resize2fs /dev/$ROOTDEVICE
fi

# Step 3: Verify the new size
echo ""
echo "Filesystem resize completed. Current usage:"
df -h /

echo ""
echo "Done."

# Note: If this still fails with the shrinking error, a reboot is required
# to fully flush the kernel's view of the disk geometry before running
# 'resize2fs /dev/mmcblk0p3' again.
