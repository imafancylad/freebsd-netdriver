#include <sys/param.h>
#include <sys/module.h>
#include <sys/kernel.h>
#include <sys/systm.h>
#include <sys/bus.h>

extern int rtl8139_probe(device_t);
extern int rtl8139_attach(device_t);
extern int rtl8139_detach(device_t);

static device_method_t rtl8139_methods[] = {
    DEVMETHOD(device_probe, rtl8139_probe),
    DEVMETHOD(device_attach, rtl8139_attach),
    DEVMETHOD(device_detach, rtl8139_detach),
    DEVMETHOD_END
};

static driver_t rtl8139_driver = { "rtl8139", rtl8139_methods, 0 }; // sizeof(softc)

DRIVER_MODULE(rtl8139, pci, rtl8139_driver, 0, 0);
MODULE_DEPEND(rtl8139, pci, 1, 1, 1);
MODULE_VERSION(rtl8139, 1);