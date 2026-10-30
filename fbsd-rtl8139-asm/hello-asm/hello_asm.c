#include <sys/param.h>
#include <sys/module.h>
#include <sys/kernel.h>

extern int hello_asm_modevent(module_t, int, void *);
static moduledata_t hello_asm_mod = { "hello_asm", hello_asm_modevent, NULL };
DECLARE_MODULE(hello_asm, hello_asm_mod, SI_SUB_DRIVERS, SI_ORDER_MIDDLE);
MODULE_VERSION(hello_asm, 1);