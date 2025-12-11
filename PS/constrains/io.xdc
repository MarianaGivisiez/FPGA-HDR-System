## Pinos de Clock do Sistema (Apenas referência, geralmente já definido no master)
# set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { sys_clock }]; 
# create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sys_clock }];

## =========================================================
## I2C (SCCB) - Usando os pinos Padrão do Header Arduino/Shield
## =========================================================
# SCL no pino "SCL" do header J3 (perto do botão RESET)
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { ov7670_scl }]; #IO_L24N_T3_34 Sch=ck_scl

# SDA no pino "SDA" do header J3
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { ov7670_sda }]; #IO_L24P_T3_34 Sch=ck_sda

## Adiciona Pull-ups internos (Opcional se sua câmera não tiver resistores de pull-up)
set_property PULLUP true [get_ports { ov7670_sda }]
set_property PULLUP true [get_ports { ov7670_scl }]


## =========================================================
## Dados da Câmera (D7-D0) - Mapeado no Pmod JA
## =========================================================
## Pinagem sugerida:
## JA1 -> D0 | JA2 -> D1 | JA3 -> D2 | JA4 -> D3
## JA7 -> D4 | JA8 -> D5 | JA9 -> D6 | JA10 -> D7

set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { ov7670_data[0] }]; #IO_L17P_T2_34 Sch=ja_p[1]
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { ov7670_data[1] }]; #IO_L17N_T2_34 Sch=ja_n[1]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { ov7670_data[2] }]; #IO_L7P_T1_34  Sch=ja_p[2]
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { ov7670_data[3] }]; #IO_L7N_T1_34  Sch=ja_n[2]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { ov7670_data[4] }]; #IO_L12P_T1_MRCC_34 Sch=ja_p[3]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { ov7670_data[5] }]; #IO_L12N_T1_MRCC_34 Sch=ja_n[3]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports { ov7670_data[6] }]; #IO_L22P_T3_34 Sch=ja_p[4]
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { ov7670_data[7] }]; #IO_L22N_T3_34 Sch=ja_n[4]


## =========================================================
## Sinais de Controle e Clocks - Mapeado no Pmod JB
## =========================================================
## Pinagem sugerida:
## JB1 -> PCLK  | JB2 -> XCLK (MCLK) | JB3 -> VSYNC | JB4 -> HREF
## JB7 -> PWDN  | JB8 -> RESET

# PCLK (Pixel Clock) - Entrada vinda da Câmera
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { ov7670_pclk }]; #IO_L8P_T1_34 Sch=jb_p[1]

# XCLK (System Clock) - Saída do FPGA para a Câmera (24MHz ou 25MHz)
set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { ov7670_xclk }]; #IO_L8N_T1_34 Sch=jb_n[1]

# VSYNC
set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { ov7670_vsync }]; #IO_L2P_T0_34 Sch=jb_p[2]

# HREF
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { ov7670_href }]; #IO_L2N_T0_34 Sch=jb_n[2]

# PWDN (Power Down) - Ativo em ALTO (Ligar no GND se não usar, ou controlar aqui)
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { ov7670_pwdn }]; #IO_L1P_T0_34 Sch=jb_p[3]

# RESET - Ativo em BAIXO (Ligar no 3.3V se não usar)
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { ov7670_reset }]; #IO_L1N_T0_34 Sch=jb_n[3]


## =========================================================
## Tratamento de Clock (CRÍTICO PARA OV7670)
## =========================================================
# O pino PCLK da câmera não está em um pino dedicado de clock global (MRCC/SRCC) no Pmod JB.
# O Vivado vai gerar um erro se você não adicionar a linha abaixo permitindo roteamento "não dedicado".
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ov7670_pclk_IBUF]