<img width="1920" height="1200" alt="PostmarketOS running on a Lenovo IdeaPad Duet Chromebook" src="https://github.com/user-attachments/assets/0d7dcbdb-e97a-4469-8b2a-96fe2993fa0e" />

# 🐧 Installing Linux on the Lenovo IdeaPad Duet Chromebook

I received a Lenovo IdeaPad Duet Chromebook from an acquaintance. Finding **Chrome OS** difficult to use, I decided to install **Linux**. I hope this guide is helpful to others with the same device.

## ⚠️ Crucial Warning: Risk and Recovery

**If you follow this guide, you will _remove_ Chrome OS and will _not_ be able to boot back into it.**

- **Proceed entirely at your own risk.** I am not responsible for any damage or loss of data.
- **Create a recovery disk FIRST!** Before starting, use the [Chromebook Recovery Utility](https://chromewebstore.google.com/detail/chromebook-recovery-utili/pocpnlppkickgojjlmhdmidojbmbodfm) to create a Chrome OS recovery disk. This is your only way to return the device to its factory Chrome OS state.

---

## 1. Introduction and Prerequisites

This guide details the process of replacing Chrome OS with a **postmarketOS** image tailored for this device.

### Device Specifications

| Component | Detail |
| :--- | :--- |
| **Device Name** | Lenovo IdeaPad Duet Chromebook (CT-X636F) |
| **Processor** | MediaTek P60T (8C: 4× A73 @ 2.0 GHz + 4× A53 @ 2.0 GHz) |
| **Operating System** | Chrome OS (initial) |
| **Memory / Storage** | 4 GB LPDDR4X / 128 GB eMMC |

### Image Preparation

This guide uses a **postmarketOS** image built for the `google-kukui` board:

- **Reference project:** [hexdump0815/imagebuilder](https://github.com/hexdump0815/imagebuilder)
- **Image used:** postmarketOS **v25.06** (Plasma desktop, for `google-kukui`).

You will need a separate computer and software such as **[balenaEtcher](https://etcher.balena.io/)** to write the `.img.xz` file to a **USB flash drive** (8 GB minimum recommended).

**💡 Tip for Chrome OS users:** You can use the **Chromebook Recovery Utility** app (available on the Chrome Web Store) to write the Linux image to your USB drive. Choose **"Use local image"** from the gear icon in the upper right. **Use this same tool to create your Chromebook recovery media.**

---

## 2. Enter Developer Mode

You must switch Chrome OS to **Developer Mode** to allow unsigned operating systems to boot.

> **⚠️ WARNING:** Entering Developer Mode performs a full Powerwash and deletes **all** data on internal storage. Back up your files now.

### Procedure for the IdeaPad Duet

1. Power off the device.
2. Press **Power** + **Volume Up** + **Volume Down** simultaneously.
3. You will see a screen prompting you to "Point to the recovery USB."
4. Press **Volume Up**, then press **Volume Up + Volume Down** together again to confirm the switch to Developer Mode.

---

## 3. Enable USB Boot

Once in Developer Mode, boot the device and open a terminal to enable booting from an external USB drive.

1. When you see the boot screen (*OS verification is OFF*), press **`Ctrl` + `Alt` + `→`** (the forward-arrow key on the top row) to open a terminal (VT2).
2. Run:

   ```bash
   # Enable USB boot and allow unsigned images
   crossystem dev_boot_usb=1 dev_boot_signed_only=0
   ```

---

## 4. Boot from USB and Install Linux

Shut down the device, insert your prepared **Linux USB drive**, and boot from it.

### Booting

1. On the *OS verification* screen, press **`Ctrl` + `D`** to initiate the USB boot.
2. The system should boot into the postmarketOS live environment on the USB.

### Login and Storage Check

1. Log in to the live environment:
   - **Username:** `linux`
   - **Password:** `changeme`

   (These may vary depending on the image — check the image documentation if they fail.)

2. Open a terminal and become root:

   ```bash
   # Become root (password: 147147 for this image; check image documentation)
   sudo -i
   ```

3. List storage devices. The internal eMMC is typically `/dev/mmcblk0`.

   ```bash
   # List all mmcblk and sd devices
   ls -d /dev/mmcblk* /dev/sd*
   ```

   **Example output** (confirm `/dev/mmcblk0` is present):

   ```
   /dev/mmcblk0
   /dev/mmcblk0boot0
   ...
   /dev/sda          # usually the USB drive
   ...
   ```

### Writing the Image to Internal Storage

Download the image to the live environment and write it directly to `/dev/mmcblk0`.

> **Version note:** The original guide referenced postmarketOS **v25.06**, but the actual image used below is **v26.06** (`20260918-0330-...`). Update the URL to match whichever image you downloaded.

1. **Download the image:**

   ```bash
   # Download the image (v26.06 GNOME build used for this guide)
   wget https://images.postmarketos.org/bpo/v26.06/google-kukui/gnome/20260918-0330/20260918-0330-postmarketOS-v26.06-gnome-4-google-kukui.img.xz
   ```

2. **Write it to the internal eMMC.**

   > **CAUTION:** Make sure `TGTDEV` is set to the **internal** drive (`mmcblk0`), not the USB drive. Verify with `lsblk` before writing.

   Save the following as `flash.sh` and run it with `sudo sh flash.sh`:

   ```bash
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
   ```

Once the write completes, **shut down** the device, remove the USB drive, and power it on. It should boot into your newly installed Linux system.

---

## 5. File System Resizing

The installed image only uses a portion of the internal storage (e.g. ~10 GB of 128 GB). You must resize the root filesystem (`/`) to use the remaining space.

1. After successfully booting into the installed Linux, open a terminal.
2. Download the resizing script:

   ```bash
   wget https://raw.githubusercontent.com/DRCRecoveryData/Installing-Linux-on-Ideapad-Chromebook/main/extend-rootfs.sh
   ```

3. Run it as root:

   ```bash
   sudo sh extend-rootfs.sh
   ```

The script will extend the root filesystem to use the full internal storage capacity. Reboot when prompted.

Verify the result:

```console
google-kukui:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk0p3  114G  3.6G  105G   3% /
```

---

## 6. Conclusion and Notes

I successfully installed and am using **postmarketOS** on my IdeaPad Duet.

- **Desktop environment:** I initially had issues with the touch panel under Xfce. Switching to **GNOME** or **Plasma** significantly improved touch operation.
- **Next steps:** For post-installation configuration and further tweaks, refer to the follow-up article *(link to be inserted)*.
