echo '===BEGINNING REPARTITIONING FOR MAINLINE LINUX==='

# Set up a place for scratch data
env set scratchaddr 0x2000000

# Select MMC device
mmc dev 1

# Clear BCB in case there's leftover recovery info
mmc erase 0x206000 4

# Clear DTB in reserved partition
mmc erase 0x14000 0x400

# Install minimal Amlogic partition table
fatload usb 0 ${scratchaddr} abridged-aml-partitions.bin 0x4000
mmc write ${scratchaddr} 0x12000 0x20

# Create GPT with our own partitions
gpt write mmc 1 'name=aml_reserved,start=0x2400000,size=0x4000000;name=env,start=0x39400000,size=0x800000;name=logo,start=0x3a400000,size=0x800000;name=factory,start=0x3fc00000,size=0x800000;name=misc,start=0x40c00000,size=0x200000;name=root,start=0x40e00000,size=0x100000000;'

# Clean up stock environment
env default -a
env delete bcb_cmd cmdline_keys factory_reset_poweroff_protect
env delete storeargs storeboot switch_bootmode update upgrade_check
env delete reboot_mode_android upgrade_step wipe_cache wipe_data

env delete recovery_from_flash recovery_from_sdcard recovery_offset recovery_part

env set setup_keys 'if keyman init 0x1234; then keyman read usid ${loadaddr} str; keyman read mac ${loadaddr} str; keyman read deviceid ${loadaddr} str; keyman read oemkey ${loadaddr} str; fi; factory_provision init;'
env set upgrade_key 'if gpio input GPIOAO_3; then echo detect upgrade key; run usb_burning; fi;'
env set preboot 'run init_display;run setup_keys;run upgrade_key'

# Set up new environment
env set bootcmd 'ext4load mmc 1:6 ${fdtaddr} /boot/dtbs/amlogic/meson-g12a-walmart-onn-streaming-box.dtb; ext4load mmc 1:6 ${loadaddr} /boot/Image; booti ${loadaddr} - ${fdtaddr};'
env set bootargs 'rw root=/dev/mmcblk1p6'

# Clean up script environment
env delete scratchaddr

# Commit environment changes
env save

echo '===REPARTITIONING DONE; RESETTING==='
reset