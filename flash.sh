#!/bin/sh
set -eu

TGTDEV=mmcblk0
IMG="$PWD/20260918-0330-postmarketOS-v26.06-gnome-4-google-kukui.img.xz"

# --- Safety checks ---
[ -b "/dev/$TGTDEV" ] || { echo "Not a block device: /dev/$TGTDEV"; exit 1; }
[ -f "$IMG" ]         || { echo "Image not found: $IMG"; exit 1; }

echo "About to write image to /dev/$TGTDEV:"
lsblk "/dev/$TGTDEV"
printf 'This will DESTROY all data on /dev/%s. Continue? [y/N] ' "$TGTDEV"
read -r ans
[ "$ans" = "y" ] || { echo "Aborted."; exit 1; }

# --- Unmount any partitions on the target ---
for part in /dev/${TGTDEV}p*; do
    [ -b "$part" ] && umount "$part" 2>/dev/null || true
done

# --- Write ---
# postmarketOS live ships BusyBox dd, which rejects status=progress.
# Prefer pv if available, else GNU dd, else plain dd.
echo "Writing $IMG to /dev/$TGTDEV ..."
if command -v pv >/dev/null 2>&1; then
    xzcat "$IMG" | pv | dd of="/dev/$TGTDEV" bs=4M conv=fsync
elif dd --help 2>&1 | grep -q 'status=progress'; then
    xzcat "$IMG" | dd of="/dev/$TGTDEV" bs=4M conv=fsync status=progress
else
    echo "Note: no pv and no dd status=progress — writing silently."
    xzcat "$IMG" | dd of="/dev/$TGTDEV" bs=4M conv=fsync
fi

sync
echo "Done."
