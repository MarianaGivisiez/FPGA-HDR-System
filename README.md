# FPGA-HDR-System
This repository implements an HDR imaging pipeline using the OV7670 camera on the Cora Z7 board. The system captures two frames with different exposure settings, stores them via VDMA, and combines them using a simple HDR fusion and tone-mapping algorithm.

## PS–PL Architecture

### Processing System (PS)

- Configures the OV7670 camera via I²C  
- Alternates between two exposure values  
- Captures the short- and long-exposure frames  
- Stores the frames in memory through the VDMA  
- Triggers the HDR processing module in the PL  

---

### Programmable Logic (PL)

- Receives the two frames (short and long exposure)  
- Sequentially reads each corresponding pair of pixels  
- Performs the image fusion in a pipelined hardware module  
- Generates the final HDR pixel for each image position  
- Sends the HDR result back to memory through the VDMA  

