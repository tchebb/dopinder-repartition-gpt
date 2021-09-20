aml_autoscript: aml_autoscript.cmd
	mkimage -A arm64 -T script -C none -n "repartition onn box" -d $< $@
