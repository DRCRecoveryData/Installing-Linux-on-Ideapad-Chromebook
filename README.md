# 🐧 Installing Linux on the Lenovo IdeaPad Duet Chromebook

<img width="1920" height="1200" alt="PostmarketOS running on a Lenovo IdeaPad Duet Chromebook" src="https://github.com/user-attachments/assets/0d7dcbdb-e97a-4469-8b2a-96fe2993fa0e" />

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
- **Image used:** postmarketOS **v26.06** (GNOME desktop, for `google-kukui`).

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
   - **Username:** `user`
   - **Password:** `147147`

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

> **Version note:** The original guide referenced postmarketOS **v25.06**, but the image used below is **v26.06** (`20260918-0330-...`). Update the URL to match whichever image you downloaded.

1. **Download the image:**

   ```bash
   # Download the image (v26.06 GNOME build used for this guide)
   wget https://images.postmarketos.org/bpo/v26.06/google-kukui/gnome/20260918-0330/20260918-0330-postmarketOS-v26.06-gnome-4-google-kukui.img.xz
   ```

2. **Write it to the internal eMMC.**

   > **CAUTION:** Make sure `TGTDEV` is set to the **internal** drive (`mmcblk0`), not the USB drive. Verify with `lsblk` before writing.

   Save the following as `flash.sh` and run it with `sudo sh flash.sh`:

   ```sh
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

   > **Why `sh` and not `bash`?** The postmarketOS live environment's `/bin/sh` is BusyBox `ash`, which does not support bash arrays. The script above is deliberately POSIX-compatible so it runs under either shell. If you invoke it as `sudo sh flash.sh`, do **not** use a bash-only version.

   > **Why no `status=progress`?** BusyBox `dd` rejects `status=progress` with `dd: invalid argument 'progress' to 'status'`. GNU coreutils `dd` accepts it. The script detects which one is available and falls back gracefully.

Once the write completes, **shut down** the device, remove the USB drive, and power it on. It should boot into your newly installed Linux system.

---

## 4b. Optional: Pre-Resize from the Live USB (No Reboot)

Most postmarketOS images auto-resize on first boot, but if you want to **pre-resize the root filesystem from the live USB environment** so the new system boots with the full disk already available, you can do it manually. This avoids a second reboot later.

### Step 1 — Fix the GPT to cover the full disk

The image is often written to a smaller virtual disk than your actual eMMC, so the GPT header sits at the wrong position. Run:

```bash
sudo parted /dev/mmcblk0 print
```

When you see:

```
Warning: Not all of the space available to /dev/mmcblk0 appears to be used...
Fix/Ignore?
```

Type **`Fix`** and press Enter.

### Step 2 — Resize partition 3 to 100% of the disk

```bash
sudo parted /dev/mmcblk0 resizepart 3 100%
```

Interact as follows:

- `Fix/Ignore?` → type `Fix` (only if asked)
- `Partition number?` → type `3`
- `End?  [<old value>]?` → type **`100%`** and press Enter

> ⚠️ **Critical:** Do **not** just press Enter at the `End?` prompt — that accepts the *old* value and the partition will **not** grow. You must explicitly type `100%`.

### Step 3 — Refresh the kernel partition table

```bash
sudo partprobe /dev/mmcblk0
```

If `partprobe` fails or does nothing, try:

```bash
sudo partx -u /dev/mmcblk0
sudo blockdev --rereadpt /dev/mmcblk0
```

### Step 4 — Check and grow the filesystem

```bash
sudo e2fsck -f /dev/mmcblk0p3
```

Wait for it to finish, then run **separately**:

```bash
sudo resize2fs /dev/mmcblk0p3
```

Expected output:

```
resize2fs 1.47.x (…)
Resizing the filesystem on /dev/mmcblk0p3 to 30394363 (4k) blocks.
The filesystem on /dev/mmcblk0p3 is now 30394363 (4k) blocks long.
```

### Step 5 — Verify

```bash
sudo parted /dev/mmcblk0 unit s print
```

```bash
sudo tune2fs -l /dev/mmcblk0p3 | grep -i "block count"
```

```bash
sudo blkid /dev/mmcblk0p3
```

Expected results:

- Partition 3 ends near `244277214s` (~116 GB)
- `Block count` ≈ `30394363` (with 4 KB blocks)
- `UUID` unchanged from before the resize (important — `/etc/fstab` references it)

### Step 6 — Shut down and boot

```bash
sudo poweroff
```

Remove the USB drive and power on. The new system should boot with the root filesystem already spanning the full eMMC.

### ⚠️ Caveats for the no-reboot method

- **Paste commands one line at a time.** If you paste a multi-line block, the shell may merge lines and produce errors like `parted: invalid token: #` or `e2fsck ... sudo resize2fs ...`.
- **`resize2fs` may report `Nothing to do!`** if the kernel still has the old partition size cached. In that case, retry the `partx`/`blockdev` refresh, or just reboot — the new system will auto-resize on first boot anyway.
- **If the GPT fix is skipped**, `parted` will keep warning and partition entries may be misaligned. Always answer `Fix` first.
- **You cannot resize the root filesystem of the *live* system this way** — this only works because `/dev/mmcblk0p3` is unmounted (the live system runs from the USB). Do not attempt this on a mounted root device.

---

## 5. File System Resizing (Post-Boot)

Most postmarketOS images — including the v26.06 image used in this guide — **auto-resize the root filesystem on first boot**. After the device boots into Linux for the first time, `/` should already span the full internal storage. Verify with:

```console
$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk0p3  112G  2.2G  104G   2% /
```

If the size shown is close to your device's full eMMC capacity (116.5 GB for the 128 GB model), **you're done — skip the rest of this section.**

### If `/` is NOT full size

Some older or custom images do not auto-resize. If `df -h /` shows something much smaller (e.g. ~4 GB), run:

```bash
# Download the file system resizing script
wget https://raw.githubusercontent.com/DRCRecoveryData/Installing-Linux-on-Ideapad-Chromebook/main/extend-rootfs.sh

# Execute as root
sudo sh extend-rootfs.sh
```

The script detects your root device and filesystem type, then expands it to fill the partition. When it reports `Nothing to do!`, that means you were already resized — it is **not** an error. Reboot after resizing.

> **Note:** If you already pre-resized from the live USB (Section 4b), the filesystem will already be full-size and this step will report `Nothing to do!`. That is expected.

---

## 6. Conclusion and Notes

I successfully installed and am using **postmarketOS v26.06 (GNOME)** on my IdeaPad Duet.

- **Desktop environment:** I initially had issues with the touch panel under Xfce. Switching to **GNOME** or **Plasma** significantly improved touch operation.
- **Storage:** After first boot, `/` occupies the full 112 GB of the internal eMMC. No manual resizing was required.
- **Next steps:** For post-installation configuration and further tweaks, refer to the follow-up article *(link to be inserted)*.

---

## Repository Files

| File | Description |
| :--- | :--- |
| `README.md` | This guide |
| `flash.sh` | Writes the postmarketOS image to internal eMMC (Section 4) |
| `extend-rootfs.sh` | Resizes the root filesystem after boot (Section 5) |
| `auto-install.sh` | All-in-one: flash + GPT fix + partition resize + filesystem resize (Sections 4 + 4b) |

---

## Quick Reference: Live USB Resize Cheat Sheet

For the no-reboot pre-resize method (Section 4b), here is the minimal command sequence:

```bash
# 1. Fix GPT (answer "Fix" at the prompt)
sudo parted /dev/mmcblk0 print

# 2. Resize partition 3 (type "3", then "100%")
sudo parted /dev/mmcblk0 resizepart 3 100%

# 3. Refresh kernel partition table
sudo partprobe /dev/mmcblk0

# 4. Check filesystem
sudo e2fsck -f /dev/mmcblk0p3

# 5. Grow filesystem
sudo resize2fs /dev/mmcblk0p3

# 6. Verify
sudo parted /dev/mmcblk0 unit s print
sudo tune2fs -l /dev/mmcblk0p3 | grep -i "block count"
```

Run each command on its own line. Do not paste the whole block at once.
