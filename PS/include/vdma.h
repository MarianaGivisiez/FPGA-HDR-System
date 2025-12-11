#ifndef VDMA_H
#define VDMA_H

#include "xaxivdma.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include <stdint.h>

/*** Adjust according to the camera resolution ***/
#define FRAME_WIDTH        640
#define FRAME_HEIGHT       480
#define BYTES_PER_PIXEL    1
#define STRIDE             (FRAME_WIDTH * BYTES_PER_PIXEL)
#define FRAME_SIZE         (STRIDE * FRAME_HEIGHT)

#define VDMA_DEVICE_ID     XPAR_AXIVDMA_0_DEVICE_ID

/*** DDR addresses of the two frames (modify according to your platform) ***/
extern uint32_t FRAME0_ADDR;
extern uint32_t FRAME1_ADDR;

/*** VDMA Functions ***/
int vdma_init();
int vdma_set_target_buffer(int frame_index);
int vdma_capture_frame(int frame_index);

#endif
