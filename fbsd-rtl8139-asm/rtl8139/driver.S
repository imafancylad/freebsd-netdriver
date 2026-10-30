#define ENXIO               6
#define BUS_PROBE_VENDOR    (-10)
#define RTL_VENDOR          0x10ec
#define RTL_DEVICE          0x8139

    .section .rodata

.Ldesc:
    .asciz  "Realtek RTL8139 Fast Ethernet (ASM driver)"

.Lmsg_attach:
    .asciz  "attached (vendor=0x10ec device=0x8139)\n"

.Lmsg_detach:
    .asciz  "detached\n"

    .text

/* int rtl8139_probe (device_t dev) */
    .globl  rtl8139_probe
    .type   rtl8139_probe, @function

rtl8139_probe:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    subq    $8, %rsp                /* align to 16 before call */
    movq    %rdi, %rbx              /* rbx = dev */

    /* vendor = pci_get_vendor(dev) */
    call    pci_get_vendor
    cmpl    $RTL_VENDOR, %eax
    jne     .Lnomatch

    /* device = pci_get_device(dev) */
    movq    %rbx, %rdi
    call    pci_get_device
    cmpl    $RTL_DEVICE, %eax
    jne     .Lnomatch

    /* match: description and high priority devolution ++ */
    movq    %rbx, %rdi
    leaq    .Ldesc(%rip), %rsi
    call    device_set_desc
    movl    $BUS_PROBE_VENDOR, %eax
    jmp     .Lprobe_out

.Lnomatch:
    movl    $ENXIO, %eax

.Lprobe_out:
    addq    $8, %rsp
    popq    %rbx
    popq    %rbp
    ret
    .size   rtl8139_probe, .-rtl8139_probe

/* int rtl8139_attach(device_t dev) */
    .globl  rtl8139_attach
    .type   rtl8139_attach, @function

rtl8139_attach:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    subq    $8, %rsp
    movq    %rdi, %rbx

    /* device_printf(dev, "...") */
    movq    %rbx, %rdi
    leaq    .Lmsg_attach(%rip), %rsi
    xorl    %eax, %eax                  /* 0 vectorial args (varargs) */
    call    device_printf

    xorl    %eax, %eax                  /* return 0; */
    addq    $8, %rsp
    popq    %rbx
    popq    %rbp
    ret
    .size   rtl8139_attach, .-rtl8139_attach

/* int rtl8139_detach(device_t dev) */
    .globl  rtl8139_detach
    .type   rtl8139_detach @function

rtl8139_detach:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    subq    $8, %rsp
    movq    %rdi, %rbx

    movq    %rbx, %rdi
    leaq    .Lmsg_detach(%rip), %rsi
    xorl    %eax, %eax
    call    device_printf

    xorl    %eax, %eax
    addq    $8, %rsp
    popq    %rbx
    popq    %rbp
    ret
    .size   rtl8139_detach, .-rtl8139_detach

    .section .note.GNU-stack,"",@progbits