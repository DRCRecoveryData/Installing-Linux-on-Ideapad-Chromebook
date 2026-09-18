#!/bin/bash
set -e

echo
echo "Attempting to complete root filesystem resize..."
echo "This step ensures the filesystem fills the expanded partition."
echo

ROOTDEVICE=$(findmnt -n -o SOURCE /)
ROOTFSTYPE=$(findmnt -n -o FSTYPE /)
PARENTDISK=$(lsblk -no PKNAME "$ROOTDEVICE")

echo "Root device: $ROOTDEVICE ($ROOTFSTYPE) on /dev/$PARENTDISK"

echo "Informing kernel of partition changes on /dev/$PARENTDISK..."
partprobe "/dev/$PARENTDISK" || true

echo "Resizing $ROOTFSTYPE filesystem on $ROOTDEVICE..."
case "$ROOTFSTYPE" in
    btrfs) btrfs filesystem resize max / ;;
    ext2|ext3|ext4) resize2fs "$ROOTDEVICE" ;;
    xfs) xfs_growfs / ;;
    *) echo "Unsupported filesystem: $ROOTFSTYPE"; exit 1 ;;
esac

echo
echo "Filesystem resize completed. Current usage:"
df -h /

echo
echo "Done."
