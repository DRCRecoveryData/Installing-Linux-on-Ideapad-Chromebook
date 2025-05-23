# Installing Linux on Ideapad Chromebook

The other day, I got a Lenovo IdeaPad Duet Chromebook from an acquaintance because they don't use it anymore.

I tried using it for a while, but I found Chrome OS difficult to use, so I decided to install Linux. I hope it will be helpful to someone.

⚠ If you do this, you will not be able to boot into ChromeOS, similar to removing (uninstalling) ChromeOS. You can create a recovery disk for the time being, so you can return it, but please ⚠ do so at your own risk

## 1. Introduction

This is the details of the equipment that will actually be used.

- **Device name:** Lenovo IdeaPad Duet Chromebook (CT-X636F)
- **Processor:** MediaTek® P60T (8C, 4x A73 @2.0GHz + 4x A53 @2.0GHz)
- **Operating system:** ChromeOS
- **Memory:** 4GB (LPDDR4X) / 128GB

This time, I created it with reference to the following site: [https://github.com/hexdump0815/imagebuilder](https://github.com/hexdump0815/imagebuilder)

I used the img file for Ubuntu 22.04 LTS (Jammy Jellyfish) published here. This is baked using software such as balenaEtcher.

* If you want to create an image file using ChromeOS, access the Chrome Web Store from the Chrome browser, search for "Chromebook Recovery Utility" and install the following tools.

After startup, you can create a Linux image file in the same way on ChromeOS by selecting "Use local image" from the gear mark in the upper right.

You can also use this tool to create Chromebook recovery media, so it's a good idea to create one just in case.

## 2. Enter developer mode

Change Chrome OS to developer mode. * When you change to developer mode, all internal files will be deleted, so please back up in advance.

If you want to change to developer mode, the operation will be different depending on the Chromebook, but in this case:

Press the power button + volume UP + volume DOWN at the same time

You will see "Point to the recovery USB", so you can change to developer mode by pressing the volume UP button and pressing Volume UP + Volume DOWN.

## 3. Enable USB boot

After changing to developer mode, you can open a terminal with CTRL+ALT. Enter the following there:

```bash
# Enable USB boot
crossystem dev_boot_usb=1 dev_boot_signed_only=0
```

## 4. USB Boot

Point to the USB memory created on the PC and boot it, and press Ctrl + D to boot USB Linux.

You can log in with your username Linux and changeme password. *I'm sorry if I'm wrong.

After that, open a terminal and check if you can see the internal storage device with the following command.

```bash
sudo -i # Password is changeme
ls -d /dev/mmcblk* /dev/sd* | cat
/dev/mmcblk0
/dev/mmcblk0boot0
/dev/mmcblk0boot1
/dev/mmcblk0p1
...
/dev/mmcblk0p12
/dev/mmcblk0rpmb
/dev/sda
/dev/sda1
/dev/sda2
/dev/sda3
/dev/sda4

df -h /boot
/dev/sda3         504M   68M  426M  14% /boot
fdisk -l
Disk /dev/mmcblk0: 29.12 GiB, 31268536320 bytes, 61071360 sectors
Units: sectors of 1 * 512 = 512 bytes
...
```

Once you have confirmed that the internal storage is visible, execute the following command.

```bash
# Download the image file to external storage (USB memory)
wget https://images.postmarketos.org/bpo/v24.12/google-kukui/gnome/20250521-0308/20250521-0308-postmarketOS-v24.12-gnome-3-google-kukui.img.xz

# Write to the target device found by the above command
export TGTDEV=mmcblk0
sudo sh -c 'xzcat "20250521-0331-postmarketOS-v24.12-phosh-22.5-go
ogle-kukui.img.xz" | dd of=/dev/mmcblk0 bs=1M'
```

When the writing is completed successfully, shut down and start from the internal storage.

## 5. File System Resizing Work

Even if you enter safely, you will not be able to use it as it is now. You will need to resize the file system.

* It used to be on GitHub mentioned earlier, but it seems to have been deleted for some reason, so please download it from the following and use it: [https://github.com/DRCRecoveryData/Installing-Linux-on-Ideapad-Chromebook/blob/main/extend-rootfs.sh](https://github.com/DRCRecoveryData/Installing-Linux-on-Ideapad-Chromebook/blob/main/extend-rootfs.sh)

```bash
wget https://github.com/DRCRecoveryData/Installing-Linux-on-Ideapad-Chromebook/blob/main/extend-rootfs.sh
sudo sh extend-rootfs.sh
```

## 6. Conclusion

Currently, my IdeaPad has successfully entered Ubuntu 22.04 LTS (Jammy Jellyfish) and can be used without any problems so far. * The following is the actual screen.

The touch panel did not work well in the Xfce desktop environment, so when I installed GNOME, I was able to operate it to some extent even with touch.
The initial settings after that are described in the following article, so please refer to it.
