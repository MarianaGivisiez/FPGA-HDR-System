#include "vdma.h"

XAxiVdma Vdma;

/*** Adjust addresses according to your DDR memory map ***/
uint32_t FRAME0_ADDR = 0x10000000;
uint32_t FRAME1_ADDR = 0x10000000 + FRAME_SIZE;

/***********************************************************************
 * Initialize VDMA (S2MM) with TWO buffers in PARKING mode
 ***********************************************************************/
int vdma_init()
{
    int Status;
    XAxiVdma_Config *cfg;
    XAxiVdma_DmaSetup dma_cfg;

    uint32_t buf_list[2] = { FRAME0_ADDR, FRAME1_ADDR };

    cfg = XAxiVdma_LookupConfig(VDMA_DEVICE_ID);
    if (!cfg) {
        xil_printf("VDMA: LookupConfig failed\n");
        return XST_FAILURE;
    }

    Status = XAxiVdma_CfgInitialize(&Vdma, cfg, cfg->BaseAddress);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA: CfgInitialize failed\n");
        return XST_FAILURE;
    }

    if (!XAxiVdma_HasS2MM(&Vdma)) {
        xil_printf("VDMA: No S2MM channel\n");
        return XST_FAILURE;
    }

    memset(&dma_cfg, 0, sizeof(dma_cfg));

    dma_cfg.VertSizeInput      = FRAME_HEIGHT;
    dma_cfg.HoriSizeInput      = STRIDE;
    dma_cfg.Stride             = STRIDE;
    dma_cfg.FrameDelay         = 0;
    dma_cfg.EnableCircularBuf  = 0;   // PARKING mode
    dma_cfg.EnableSync         = 0;
    dma_cfg.PointNum           = 0;
    dma_cfg.EnableFrameCounter = 0;

    Status = XAxiVdma_DmaConfig(&Vdma, XAXIVDMA_WRITE, &dma_cfg);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA: DmaConfig failed\n");
        return XST_FAILURE;
    }

    Status = XAxiVdma_DmaSetBufferAddr(&Vdma, XAXIVDMA_WRITE, buf_list);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA: SetBufferAddr failed\n");
        return XST_FAILURE;
    }

    Status = XAxiVdma_DmaStart(&Vdma, XAXIVDMA_WRITE);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA: DmaStart failed\n");
        return XST_FAILURE;
    }

    /* Select the first buffer initially */
    Status = XAxiVdma_StartParking(&Vdma, 0, XAXIVDMA_WRITE);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA: StartParking failed\n");
        return XST_FAILURE;
    }

    xil_printf("VDMA initialized successfully.\n");

    return XST_SUCCESS;
}

/***********************************************************************
 * Manually select which buffer the camera will write into
 ***********************************************************************/
int vdma_set_target_buffer(int frame_index)
{
    if (frame_index < 0 || frame_index > 1)
        return XST_FAILURE;

    return XAxiVdma_StartParking(&Vdma, frame_index, XAXIVDMA_WRITE);
}

/***********************************************************************
 * Capture a frame on demand
 ***********************************************************************/
int vdma_capture_frame(int frame_index)
{
    if (frame_index < 0 || frame_index > 1)
        return XST_FAILURE;

    xil_printf("VDMA: capturing frame %d...\n", frame_index);

    /* Select the destination buffer */
    vdma_set_target_buffer(frame_index);

    /* Wait for 1 complete frame (~33 ms at VGA 30 FPS) */
    usleep(40000);

    /* Invalidate cache before CPU reads the frame */
    uint32_t addr = (frame_index == 0) ? FRAME0_ADDR : FRAME1_ADDR;
    Xil_DCacheInvalidateRange(addr, FRAME_SIZE);

    xil_printf("VDMA: frame %d captured.\n", frame_index);

    return XST_SUCCESS;
}
