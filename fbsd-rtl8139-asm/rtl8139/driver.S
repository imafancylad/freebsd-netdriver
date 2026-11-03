/*
 * driver.S — newbus + access HW for RTL8139 (FreeBSD 14.x amd64)
 *
 * Registros RTL8139 (I/O ports, offset desde BAR0):
 *   0x37  CR   Command Register (1B)
 *   0x3C  IMR  Interrupt Mask Register (2B)
 *   0x3E  ISR  Interrupt Status Register (2B)
 *   0x40  TCR  Transmit Configuration Register (4B)
 *   0x44  RCR  Receive Configuration Register (4B)
 *   0x00  IDR0..IDR5  MAC address
 */

#include "common.h"

#define	ENXIO			    6
#define	ENOMEM			    12
#define	BUS_PROBE_VENDOR	(-10)
#define	RTL_VENDOR		    0x10ec
#define	RTL_DEVICE		    0x8139

/* sys/sys/bus.h */
#define	SYS_RES_IOPORT		4

/* sys/sys/rman.h */
#define	RF_ACTIVE		0x0002

	.section .rodata

.Ldesc:
    .asciz "Realtek RTL8139 Fast Ethernet (ASM driver)"

.Lfmt_attach:
    .asciz "attached (vendor=0x10ec device=0x8139)\n"

.Lfmt_bar:
    .asciz "BAR I/O: handle=0x%lx\n"

.Lfmt_mac:
    .asciz "MAC = %02x:%02x:%02x:%02x:%02x:%02x\n"

.Lfmt_cr_reset:
    .asciz "CR after reset = 0x%02x (RxBufEmpty expected)\n"

.Lfmt_tcr:
    .asciz "TCR HW version = %u\n"

.Lfmt_rcr:
	.asciz "RCR = 0x%08x\n"

.Lfmt_tcr_rw:
	.asciz "TCR = 0x%08x (functional lower bits, alt = version HW)\n"

.Lfmt_cr_init:
	.asciz "CR after init = 0x%02x (expected 0x0d = RxBufEmpty|TE|RE)\n"

.Lfmt_init_ok:
	.asciz "init OK\n"

.Lfmt_detach:
	.asciz "detached\n"

	.text

/* int rtl8139_probe(device_t dev) */
	.globl	rtl8139_probe
	.type	rtl8139_probe, @function

rtl8139_probe:
	pushq	%rbp
	pushq	%rbx
	subq	$8, %rsp
	movq	%rdi, %rbx

	call	pci_get_vendor
	cmpl	$RTL_VENDOR, %eax
	jne		.Lnomatch

	movq	%rbx, %rdi
	call	pci_get_device
	cmpl	$RTL_DEVICE, %eax
	jne		.Lnomatch

	movq	%rbx, %rdi
	leaq	.Ldesc(%rip), %rsi
	call	device_set_desc
	movl	$BUS_PROBE_VENDOR, %eax
	jmp		.Lprobe_out

.Lnomatch:
	movl	$ENXIO, %eax

.Lprobe_out:
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.size	rtl8139_probe, .-rtl8139_probe

/* int rtl8139_attach(device_t dev) */
/* rbx = dev, r12 = softc, r13 = handle, r14 = scratch */
	.globl	rtl8139_attach
	.type	rtl8139_attach, @function

rtl8139_attach:
	pushq	%rbp
	pushq	%rbx
	pushq	%r12
	pushq	%r13
	pushq	%r14
	subq	$8, %rsp					/* 5 push + 8 = 48 | rsp%16 == 0 */
	movq	%rdi, %rbx					/* rbx = dev */

/* softc = device_get_softc(dev) */
	call	device_get_softc
	movq	%rax, %r12					/* r12 = softc */
	movq	%rbx, RTL_SC_DEV(%r12)		/* softc->dev = dev */

/* device_printf(dev, "attached...") */
	movq	%rbx, %rdi
	leaq	.Lfmt_attach(%rip), %rsi
	xorl	%eax, %eax
	call	device_printf

/* res = bus_alloc_resource(dev, SYS_RES_IOPORT, &rid, 0, ~0, 1, RF_ACTIVE) */
	movl	$RTL_RID_IO, RTL_SC_IO_RID(%r12)
	subq	$16, %rsp
	movl	$RF_ACTIVE, (%rsp)
	movq	%rbx, %rdi
	movl	$SYS_RES_IOPORT, %esi
	leaq	RTL_SC_IO_RID(%r12), %rdx
	xorl	%ecx, %ecx
	movq	$-1, %r8
	movl	$1, %r9d
	call	bus_alloc_resource
	addq	$16, %rsp

	testq	%rax, %rax
	jz		.Lattach_fail
	movq	%rax, RTL_SC_IO_RES(%r12)

	/* tag/handle */
	movq	%rax, %rdi
	call	rman_get_bustag
	movq	%rax, RTL_SC_IO_TAG(%r12)

	movq	RTL_SC_IO_RES(%r12), %rdi
	call	rman_get_bushandle
	movq	%rax, RTL_SC_IO_HANDLE(%r12)
	movq	%rax, %r13						/* r13 = handle (for outb/inb) */

	/* device_printf(dev, "BAR I/O handle=0x%lx", handle) */
	movq	%r13, %rdx
	movq	%rbx, %rdi
	leaq	.Lfmt_bar(%rip), %rsi
	xorl	%eax, %eax
	call	device_printf

	/* read MAC in softc->,ac[0..5] */
	xorl	%r14d, %r14d

.Lmac_loop:
	movl	%r14d, %edx
	addl	%r13d, %edx
	inb		%dx, %al
	movb	%al, RTL_SC_MAC(%r12,%r14,1)
	incl	%r14d
	cmpl	$6, %r14d
	jl		.Lmac_loop

	/* device_printf(dev, "MAC = ...", b0..b5) */
	subq	$16, %rsp
	movzbl	RTL_SC_MAC+4(%r12), %eax
	movq	%rax, 0(%rsp)
	movzbl	RTL_SC_MAC+5(%r12), %eax
	movq	%rax, 8(%rsp)

	movq	%rbx, %rdi
	leaq	.Lfmt_mac(%rip), %rsi
	movzbl	RTL_SC_MAC+0(%r12), %edx
	movzbl	RTL_SC_MAC+1(%r12), %ecx
	movzbl	RTL_SC_MAC+2(%r12), %r8d
	movzbl	RTL_SC_MAC+3(%r12), %r9d
	xorl	%eax, %eax
	call	device_printf
	addq	$16, %rsp

	/* --- chip reset --- */
	movl	%r13d, %edx
	addl	$RTL_CR, %edx
	movb	$RTL_CR_RST, %al
	outb	%al, %dx

	/* wait to clean RST (1M timeout) */
	movl	$1000000, %r14d

.Lwait_rst:
	movl	%r13d, %edx
	addl	$RTL_CR, %edx
	inb		%dx, %al
	testb	$RTL_CR_RST, %al
	jz		.Lrst_done
	decl	%r14d
	jnz		.Lwait_rst

.Lrst_done:
	/* print CR after reset */
	movl	%r13d, %edx
	addl	$RTL_CR, %edx
	inb		%dx, %al
	movzbl	%al, %edx
	movq	%rbx, %rdi
	leaq	.Lfmt_cr_reset(%rip), %rsi
	xorl	%eax, %eax
	call	device_printf

	/* read HW version of TCR */
	movl	%r13d, %edx
	addl	$RTL_TCR, %edx
	inl		%dx, %eax
	shrl	$28, %eax
	movl	%eax, %edx
	movq	%rbx, %rdi
	leaq	.Lfmt_tcr(%rip), %rsi
	xorl	%eax, %eax
	call	device_printf

	/* --- init: IMR = 0, ISR = 0xFFFF (clear) --- */
	movl	%r13d, %edx
	addl	$RTL_IMR, %edx
	xorl	%eax, %eax
	outw	%ax, %dx

	movl	%r13d, %edx
	addl	$RTL_ISR, %edx
	movl	$0xFFFF, %eax
	outw	%ax, %dx

	/* --- RCR = 0x0F --- */
	movl	%r13d, %edx
	addl	$RTL_RCR, %edx
	movl	$RTL_INIT_RCR, %eax
	outl	%eax, %dx

	movl	%r13d, %edx
	addl	$RTL_RCR, %edx
	inl		%dx, %eax
	movl	%eax, %edx
	movq	%rbx, %rdi
	leaq	.Lfmt_rcr(%rip), %rsi
	xorl	%eax, %eax
	call	device_printf

	/* --- TCR = 0x03000700 --- */
	movl	%r13d, %edx
	addl	$RTL_TCR, %edx
	movl	$RTL_INIT_TCR, %eax
	outl	%eax, %dx

	movl	%r13d, %edx
	addl	$RTL_TCR, %edx
	inl		%dx, %eax
	movl	%eax, %edx
	movq	%rbx, %rdi
	leaq	.Lfmt_tcr_rw(%rip), %rsi
	xorl	%eax, %eax
	call	device_printf

	/* --- CR = RE | TE (without RST) --- */
	movl	%r13d, %edx
	addl	$RTL_CR, %edx
	movb	$(RTL_CR_RE|RTL_CR_TE), %al
	outb	%al, %dx

	/* Read CR to confirm (it must be 0x0D) */
	movl	%r13d, %edx
	addl	$RTL_CR, %edx
	inb		%dx, %al
	movzbl	%al, %edx
	movq	%rbx, %rdi
	leaq	.Lfmt_cr_init(%rip), %rsi
	xorl	%eax, %eax
	call	device_printf

	/* "init OK" */
	movq	%rbx, %rdi
	leaq	.Lfmt_init_ok(%rip), %rsi
	xorl	%eax, %eax
	call	device_printf

	xorl	%eax, %eax
	jmp		.Lattach_out

.Lattach_fail:
	movq	RTL_SC_IO_RES(%r12), %rcx
	testq	%rcx, %rcx
	jz		.Lattach_fail_ret
	movq	%rbx, %rdi
	movl	$SYS_RES_IOPORT, %esi
	movl	$RTL_RID_IO, %edx
	call	bus_release_resource
	movq	$0, RTL_SC_IO_RES(%r12)

.Lattach_fail_ret:
	movl	$ENOMEM, %eax

.Lattach_out:
	addq	$8, %rsp
	popq	%r14
	popq	%r13
	popq	%r12
	popq	%rbx
	popq	%rbp
	ret
	.size	rtl8139_attach, .-rtl8139_attach

/* int rtl8139_detach(device_t dev) */
	.globl	rtl8139_detach
	.type	rtl8139_detach, @function

rtl8139_detach:
	pushq	%rbp
	pushq	%rbx
	pushq	%r12
	subq	$8, %rsp				/* 3 push + 8 = 32 -> rsp%16 == 0 */
	movq	%rdi, %rbx

	call	device_get_softc
	movq	%rax, %r12

	/* chip shutdown: CR = 0 */
	movq	RTL_SC_IO_HANDLE(%r12), %rdx
	testq	%rdx, %rdx
	jz		.Ldetach_release
	addl	$RTL_CR, %edx
	xorl	%eax, %eax
	outb	%al, %dx

	/* free BAR */
	movq	%rbx, %rdi
	movl	$SYS_RES_IOPORT, %esi
	movl	$RTL_RID_IO, %edx
	movq	RTL_SC_IO_RES(%r12), %rcx
	call	bus_release_resource
	movq	$0, RTL_SC_IO_RES(%r12)
	movq	$0, RTL_SC_IO_HANDLE(%r12)

.Ldetach_release:
	movq	%rbx, %rdi
	leaq	.Lfmt_detach(%rip), %rsi
	xorl	%eax, %eax
	call	device_printf

	xorl	%eax, %eax
	addq	$8, %rsp
	popq	%r12
	popq	%rbx
	popq	%rbp
	ret
	.size	rtl8139_detach, .-rtl8139_detach

	.section .note.GNU-stack,"",@progbits