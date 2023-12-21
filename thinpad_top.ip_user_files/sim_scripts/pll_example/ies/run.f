-makelib ies_lib/xpm -sv \
  "E:/Vivado/Vivado/2019.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "E:/Vivado/Vivado/2019.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies_lib/xpm \
  "E:/Vivado/Vivado/2019.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../thinpad_top.srcs/sources_1/ip/pll_example/pll_example_clk_wiz.v" \
  "../../../../thinpad_top.srcs/sources_1/ip/pll_example/pll_example.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

