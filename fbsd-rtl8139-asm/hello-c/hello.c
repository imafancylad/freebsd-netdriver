#include <sys/param.h>
#include <sys/module.h>
#include <sys/kernel.h>
#include <sys/systm.h>
#include <sys/errno.h>


// not able to unload
static int hello_modevent(module_t mod, int type, void *data)
{
    switch (type)
    {
        case MOD_LOAD:
            printf("hello: module loaded\n");
            break;

        case MOD_UNLOAD:
            printf("hello: module unloaded\n");

        case MOD_QUIESCE:
        case MOD_SHUTDOWN:
            break;

        default:
            return (EOPNOTSUPP);
    }

    return 0;
}

static moduledata_t hello_mod = { "hello", hello_modevent, NULL };

DECLARE_MODULE(hello, hello_mod, SI_SUB_DRIVERS, SI_ORDER_MIDDLE);
MODULE_VERSION(hello, 1);