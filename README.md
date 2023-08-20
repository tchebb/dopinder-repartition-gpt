## WARNING

Do not attempt to use this tool unless you have read `aml_autoscript.cmd` and
understand both the intent behind and the exact effect of every line. This is
not a ready-to-use tool; it's a best-effort script that performs one step in an
intricate process that, if not done right, **will brick your device**.

Specifically, repartitioning the device involves moving the first-, second-,
and third-stage bootloaders (BL2, BL31, and BL32/U-Boot respectively) from the
main eMMC region to the boot0 and/or boot1 regions to make room for a standard
GPT partition table on the main region. This script does not perform that move,
but it does overwrite the main-region bootloader. **If you run this script
before manually relocating your device's bootloaders, you're guaranteed to
brick your device.** If that happens, you can only recover it by physically
replacing or rewriting the eMMC.

## Purpose

This is a U-Boot script designed to run on the Walmart onn. Google TV 4K
Streaming Box (1st Generation), which unfortunately has no vendor-provided
codename. LineageOS [calls][lineage-xda] this device "dopinder", so I'll call
it that too.

The script creates a GPT partition table, suitable for holding a desktop Linux
distro, in the main eMMC region. It also replaces Amlogic's proprietary "MPT"
partition table, which is the only partition table on the stock image, with a
minimal one that lists only partitions needed for U-Boot to function. Likewise,
it removes Android-specific configuration from U-Boot's environment and adds
configuration to boot a distro like Arch or Debian from GPT.

As mentioned above, the GPT partition table created by this script overwrites
boot code in the main eMMC region. On a stock device, the main region is the
only place where that code exists, so **you must not run this script without
putting a copy of that boot code in the boot0 and/or boot1 regions**. Luckily,
the BootROM and stock bootloaders all support running out of boot0/boot1, so a
all that entails is copying the stock (signed) boot code byte-for-byte.

## Usage

 1. Using the stock U-Boot shell (`amlmmc`) or Linux booted from RAM (`dd
    /dev/mmcblk*`), copy data starting at address `0x200` and ending at address
    `0x3f_ffff` in the main eMMC region to the matching addresses in the boot0
    and/or boot1 eMMC regions. That is, copy the first 4MiB over but preserve
    the first 0x200 bytes of the boot region (which holds DDR configuration)
    instead of replacing it with the first 0x200 bytes of the main region
    (which is all zeroes).
 2. Zero out the first 4MiB of the main eMMC region. This is probably optional,
    but it's nice not to lave partially-clobbered and unusable code there for
    debugging purposes. If you did step #1 wrong, this step will brick your onn
    box. Unfortunately, there's no way to test step #1 without doing this, as
    the BootROM tries booting from the main region before it falls back to
    boot0 and boot1.
 3. Run `make` in this repo and copy both the resulting `aml_autoscript` and
    `abridged-aml-partitions.bin` to the root of a USB drive. Connect that to
    your dopinder device with a powered USB OTG cable, then boot the device.
    The script should automatically run and repartition your device. The script
    doesn't make backups, so restoring to stock is not easy once you do this.
    However, assuming you did steps #1 and #2, there should be no further risk
    of bricking at this point. If you didn't do step #2, this may be what
    bricks the device.

## Files

 - `aml_autoscript.cmd`: Script that U-Boot in its stock config will run off a
   USB drive. Compiles to `aml_autoscript`.
 - `abridged-aml-partitions.bin`: Amlogic partition table containing only
   reserved, env, logo, factory, and misc. Contains a dummy entry at index 0 to
   make Amlogic's 0-based partition indices line up with GPT's 1-based ones.

## Resources

 - [dopinder on Exploitee.rs wiki](https://exploitee.rs/index.php/ONN_4K_Box)
 - [dopinder LinageOS build][lineage-xda]
 - [dopinder Debian tooling](https://github.com/riptidewave93/dopinder-debian)
 - [Amlogic "MPT" partition table](https://github.com/kaitai-io/kaitai_struct_formats/blob/master/filesystem/amlogic_emmc_partitions.ksy)

[lineage-xda]: https://forum.xda-developers.com/t/official-unofficial-lineageos-19-1-for-amlogic-g12-sm1-family-devices.4313743/

## TODO

 - Make this script copy the bootloader to boot0/boot1 itself. This ought to be
   perfectly possible a significantly decrease the brick risk; I just haven't
   had time to implement and fully test it.
 - Expand this README to include details of what each boot stage reads from the
   eMMC and where it expects that data to be.
