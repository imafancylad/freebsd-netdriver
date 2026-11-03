#ifndef _RTL8139_COMMON_H_
#define _RTL8139_COMMON_H_

#define RTL_SC_DEV          0       /* device_t             */
#define RTL_SC_IFP          8       /* struct ifnet *       */
#define RTL_SC_IO_RES       16      /* struct resource *    */
#define RTL_SC_IO_RID       24      /* int                  */
#define RTL_SC_IRQ_RES      32      /* struct resource *    */
#define RTL_SC_IRQ_RID      40      /* int                  */
#define	RTL_SC_IO_TAG       48      /* bus_space_tag_t      */
#define	RTL_SC_IO_HANDLE    56      /* bus_space_handle_t   */
#define	RTL_SC_IRQ_COOKIE   64      /* void                 */
#define	RTL_SC_MAC          72      /* uint8_t[6]           */
#define	RTL_SC_MAC_PAD      78      /* uint8_t[2]           */
#define	RTL_SC_SIZE         80

#define	RTL_IDR0		    0x00
#define	RTL_CR			    0x37
#define	RTL_IMR			    0x3C
#define	RTL_ISR			    0x3E
#define	RTL_TCR			    0x40
#define	RTL_RCR			    0x44

#define	RTL_CR_BUFE         0x01    /* RxBufEmpty           */
#define	RTL_CR_TE           0x04    /* Transmit Enable      */
#define	RTL_CR_RE           0x08    /* Receive Enable       */
#define	RTL_CR_RST          0x010   /* Reset                */

#define RTL_INIT_RCR        0x0000000F
#define RTL_INIT_TCR        0x03000700

#define	RTL_RID_IO          0x010
#define	RTL_RID_IRQ         0x14

#endif