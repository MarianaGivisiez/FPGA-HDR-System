#include "camera_config.h"

int main(void)
{
    xil_printf("Initializing OV7670 camera...\r\n");

    /******************************
     * 1) Initialize I2C and camera
     ******************************/

#ifndef SDT
    int Status = i2c_init(IIC_DEVICE_ID);
#else
    int Status = i2c_init(XIICPS_BASEADDRESS);
#endif

    if (Status != XST_SUCCESS) {
        xil_printf("Failed to configure camera!\r\n");
        while(1);
    }

    xil_printf("Camera configured.\r\n");

    /******************************
     * 2) Initialize VDMA (parking mode)
     ******************************/
    xil_printf("Initializing VDMA...\r\n");

    Status = vdma_init();
    if (Status != XST_SUCCESS) {
        xil_printf("Error initializing VDMA!\r\n");
        return XST_FAILURE;
    }

    xil_printf("VDMA ready.\r\n");

    xil_printf("EXPOSURE_LOW  = %d\r\n", EXPOSURE_LOW);
    xil_printf("EXPOSURE_HIGH = %d\r\n", EXPOSURE_HIGH);

    /******************************
     * 3) HDR capture loop
     ******************************/
    while (1)
    {
        /*********************
         * SHORT-EXPOSURE FRAME
         *********************/
        xil_printf("\n--- Capturing SHORT frame ---\r\n");
        ov7670_set_exposure(EXPOSURE_LOW);

        // write into BUFFER0 (FRAME0_ADDR)
        vdma_capture_frame(0);

        xil_printf("Short frame stored in buffer 0.\r\n");

        /*********************
         * LONG-EXPOSURE FRAME
         *********************/
        xil_printf("\n--- Capturing LONG frame ---\r\n");
        ov7670_set_exposure(EXPOSURE_HIGH);

        // write into BUFFER1 (FRAME1_ADDR)
        vdma_capture_frame(1);

        xil_printf("Long frame stored in buffer 1.\r\n");

        // small delay
        usleep(10000);
    }

    return 0;
}
