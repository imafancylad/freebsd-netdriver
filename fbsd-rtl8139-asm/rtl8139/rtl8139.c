#include <sys/param.h>
#include <sys/module.h>
#include <sys/kernel.h>
#include <sys/systm.h>
#include <sys/bus.h>
#include <sys/rman.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/if_var.h>
#include <net/ethernet.h>

#include "common.h"

extern int rtl8139_probe(device_t);
extern int rtl8139_attach(device_t);
extern int rtl8139_detach(device_t);

struct rtl_softc {
    device_t            dev;            /* 0 */
    struct ifnet        *ifp;           /* 8 */
    struct resource     *io_res;        /* 16 */
    int                 io_rid;         /* 24 */
    struct resource     *irq_res;       /* 32 */
    int                 irq_rid;        /* 40 */
    bus_space_tag_t     io_tag;         /* 48 */
    bus_space_handle_t  io_handle;      /* 56 */
    void                *irq_cookie;    /* 64 */
    uint8_t             mac[6];         /* 72 */
    uint8_t             mac_pad[2];     /* 78 */
};

_Static_assert(sizeof(struct rtl_softc) == RTL_SC_SIZE, "rtl_softc size mismatch with RTL_SC_SIZE");

static device_method_t rtl8139_methods[] = {
    DEVMETHOD(device_probe, rtl8139_probe),
    DEVMETHOD(device_attach, rtl8139_attach),
    DEVMETHOD(device_detach, rtl8139_detach),
    DEVMETHOD_END
};

static driver_t rtl8139_driver = { "rtl8139", rtl8139_methods, sizeof(struct rtl_softc) };

DRIVER_MODULE(rtl8139, pci, rtl8139_driver, 0, 0);
MODULE_DEPEND(rtl8139, pci, 1, 1, 1);
MODULE_VERSION(rtl8139, 1);