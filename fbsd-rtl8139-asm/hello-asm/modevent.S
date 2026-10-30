#define MOD_LOAD        0
#define MOD_UNLOAD      1
#define MOD_SHUTDOWN    2
#define MOD_QUIESCE     3

#define EOPNOTSUPP      45

    .section .rodata

.Lmsg_load:
    .asciz  "hello_asm: loaded from ASM\n"

.Lmsg_unload:
    .asciz  "hello_asm: unloaded from ASM\n"

    .text
    .globl  hello_asm_modevent
    .type   hello_asm_modevent, @function

hello_asm_modevent:
    pushq   %rbp
    movq    %rsp, %rbp

    cmpl    $MOD_LOAD, %esi
    je      .Lload
    cmpl    $MOD_UNLOAD, %esi
    je      .Lunload
    cmpl    $MOD_SHUTDOWN, %esi
    je      .Lok
    cmpl    $MOD_QUIESCE, %esi
    je      .Lok

    /* unknown type */
    movl    $EOPNOTSUPP, %eax
    popq    %rbp
    ret

.Lload:
    leaq    .Lmsg_load(%rip), %rdi
    jmp     .Lprint

.Lunload:
    leaq    .Lmsg_unload(%rip), %rdi

.Lprint:
    /* call to print require alignment to 16 (sysV) */
    /* eax = 0 -> "no vectorial arguments" (varargs) */
    xorl    %eax, %eax
    call    printf
    xorl    %eax, %eax                  /* return 0; */
    popq    %rbp
    ret

.Lok:
    xorl    %eax, %eax
    popq    %rbp
    ret

    .size   hello_asm_modevent, .-hello_asm_modevent

    .section .note.GNU-stack,"",@progbits