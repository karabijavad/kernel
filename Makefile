# qemu-system-x86_64 --enable-kvm --kernel /boot/vmlinuz-4.10.0-rc8+ --initrd /boot/initrd.img-4.10.0-rc8+ --drive file=/dev/javad/gentoo,if=virtio -m 4096 --nographic --cpu host --append "root=/dev/vda console=ttyS0 rootflags=subvol=gentoo init=/lib/systemd/systemd"

.PHONY: linux root initramfs

linux:
	cd linux &&\
		nice -n 20 $(MAKE) -j9

initramfs:
	./linux/scripts/gen_initramfs_list.sh ./initramfs > ./initramfs_list
	./linux/usr/gen_init_cpio ./initramfs_list | gzip -1 > ./root/boot/initramfs.cpio.gz

root: initramfs linux
	cd linux &&\
	$(MAKE) modules_install INSTALL_MOD_PATH=$(CURDIR)/root &&\
	$(MAKE) install INSTALLKERNEL=$(CURDIR)/installkernel INSTALL_PATH=$(CURDIR)/root/boot

run: root
	qemu-system-x86_64 \
		--enable-kvm \
		--kernel ./root/boot/vmlinuz \
		--initrd ./root/boot/initramfs.cpio.gz \
		-m 4096 \
		--nographic \
		--cpu host \
		--append "root=/dev/vda console=ttyS0"
