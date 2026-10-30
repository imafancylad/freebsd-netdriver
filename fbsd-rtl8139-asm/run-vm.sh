#!/usr/bin/env bash
set -e
DIR=$HOME/proyectos/freebsd-netdriver/fbsd-rtl8139-asm
exec qemu-system-x86_64 \
  -machine q35,accel=kvm -cpu host \
  -smp 4 -m 4096 \
  -drive file="$DIR/disk.qcow2",if=virtio,format=qcow2 \
  -boot order=c \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device rtl8139,netdev=net1 \
  -netdev user,id=net1 \
  -virtfs local,path="$DIR",mount_tag=hostshare,security_model=none \
  -display gtk -vga std
