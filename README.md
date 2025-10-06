# 🐧 Installing Linux on Lenovo IdeaPad Duet Chromebook

I received a Lenovo IdeaPad Duet Chromebook from an acquaintance. Finding **Chrome OS** difficult to use, I decided to install **Linux**. I hope this guide is helpful to others with the same device.

## ⚠️ **Crucial Warning: Risk and Recovery**

**If you follow this guide, you will be *removing* Chrome OS and will *not* be able to boot back into it.**

* **Proceed entirely at your own risk.** I am not responsible for any damage or loss of data.
* **Create a Recovery Disk FIRST!** Before starting, use the **Chromebook Recovery Utility** to create a Chrome OS recovery disk. This is your only way to return the device to its factory Chrome OS state.

***

## 1. Introduction and Prerequisites

This guide details the process of replacing Chrome OS with a **PostmarketOS** image tailored for the device.

### Device Specifications

| Component | Detail |
| :--- | :--- |
| **Device Name** | Lenovo IdeaPad Duet Chromebook (CT-X636F) |
| **Processor** | MediaTek® P60T (8C, 4x A73 @2.0GHz + 4x A53 @2.0GHz) |
| **Operating System** | ChromeOS (Initial) |
| **Memory/Storage** | 4GB (LPDDR4X) / 128GB (eMMC) |

### Image Preparation

This guide uses a **PostmarketOS** image. The specific image used for reference is for the `google-kukui` board:

* **Reference Site:** [hexdump0815/imagebuilder](https://github.com/hexdump0815/imagebuilder)
* **Image Used:** PostmarketOS **v25.06** (Plasma Desktop environment, for `google-kukui`).

You will need a separate computer and software like **balenaEtcher** to write the `.img.xz` file to a **USB flash drive** (at least 8GB recommended).

**💡 Tip for ChromeOS Users:** You can use the **Chromebook Recovery Utility** app (available on the Chrome Web Store) to write the Linux image to your USB drive. Select the **"Use local image"** option from the gear icon in the upper right. **Use this tool to create your Chromebook recovery media as well!**

***

## 2. Enter Developer Mode

You must switch Chrome OS to **Developer Mode** to allow unsigned operating systems to boot.

**⚠️ WARNING: Entering Developer Mode will perform a full Powerwash, deleting ALL data on the internal storage. Backup your files now.**

### Procedure for IdeaPad Duet:

1.  Power off the device.
2.  Press the **Power Button** + **Volume UP** + **Volume DOWN** simultaneously.
3.  You will see a screen prompting to "Point to the recovery USB."
4.  Press the **Volume UP** button, and then press **Volume UP + Volume DOWN** together again to confirm the switch to Developer Mode.

***

## 3. Enable USB Boot

Once in Developer Mode, boot the device and open a terminal to enable booting from an external USB drive.

1.  When you see the boot screen (OS verification is OFF), press **`CTRL` + `ALT` + `>`** (the forward arrow key on the top row) to open a terminal (VT2).
2.  Enter the following command:

```bash
# Enable USB boot and allow unsigned images
crossystem dev_boot_usb=1 dev_boot_signed_only=0
````

-----

## 4\. Boot from USB and Install Linux

Shut down the device, insert your prepared **Linux USB drive**, and boot from it.

### Booting

1.  On the OS verification screen, press **`CTRL` + `D`** to initiate the USB boot process.
2.  The system should boot into the PostmarketOS live environment on the USB.

### Login and Storage Check

1.  Log in to the Live environment:
      * **Username:** `linux`
      * **Password:** `changeme` (This may vary depending on the image; check the image documentation if it fails).
2.  Open a terminal and become root to check the internal storage devices.

<!-- end list -->

```bash
# Become root (Password: 147147 for this image, check image documentation)
sudo -i
```

3.  List the storage devices. The internal eMMC drive is typically `/dev/mmcblk0`.

<!-- end list -->

```bash
# List all mmcblk and sd devices
ls -d /dev/mmcblk* /dev/sd* | cat
```

**Example Output:** (Confirm `/dev/mmcblk0` is present)

```
/dev/mmcblk0
/dev/mmcblk0boot0
...
/dev/sda  # This is usually the USB drive
...
```

### Writing the Image to Internal Storage

The following commands download the image again (to the USB drive's temporary storage, `/tmp` is safer if the user hasn't explicitly checked the working directory) and write it directly to the internal storage device (`/dev/mmcblk0`).

1.  **Download the Image:**
      * *Note: I've fixed the malformed link from the original file.*

<!-- end list -->

```bash
# Download the image file (v25.06 Plasma Desktop used for this guide)
wget https://images.postmarketos.org/bpo/v25.06/google-kukui/plasma-desktop/20251003-0331/20251003-0331-postmarketOS-v25.06-plasma-desktop-3-google-kukui.img.xz
```

2.  **Write to Internal eMMC:**
      * **CAUTION: Ensure `TGTDEV` is set to your internal drive\! It should be `mmcblk0`.**

<!-- end list -->

```bash
# Set the target device variable (Internal eMMC)
export TGTDEV=mmcblk0

# Write the image to the internal drive (/dev/mmcblk0)
sudo sh -c 'xzcat "20251003-0331-postmarketOS-v25.06-plasma-desktop-3-google-kukui.img.xz" | dd of=/dev/mmcblk0 bs=1M status=progress'
```

Once the write completes, **shut down** the device, remove the USB, and power it on. It should boot into your newly installed Linux system.

-----

## 5\. File System Resizing

The installed image only uses a portion of the internal storage (e.g., $10$ GB of $128$ GB). You must resize the root filesystem (`/`) to use the remaining space.

1.  After successfully booting into the installed Linux, open a terminal.
2.  Download the provided resizing script:

<!-- end list -->

```bash
# Download the file system resizing script
wget https://raw.githubusercontent.com/DRCRecoveryData/Installing-Linux-on-Ideapad-Chromebook/main/extend-rootfs.sh
```

3.  Execute the script as root:

<!-- end list -->

```bash
# Execute the resizing script
sudo sh extend-rootfs.sh
```

The script will automatically extend the root filesystem to utilize the full internal storage capacity. Reboot when prompted or after execution.

-----

## 6\. Conclusion and Notes

I successfully installed and am using **PostmarketOS v25.06** on my IdeaPad Duet.

  * **Desktop Environment:** I initially had issues with the touch panel in the Xfce environment. Switching to the **GNOME** or **Plasma** desktop environment significantly improved touch operation.
  * **Next Steps:** For post-installation configurations and further tweaks, refer to the follow-up article (link to be inserted here).
