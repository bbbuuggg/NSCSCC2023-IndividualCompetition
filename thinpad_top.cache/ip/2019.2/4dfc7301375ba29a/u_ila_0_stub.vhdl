-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Wed Aug 16 18:47:39 2023
-- Host        : DESKTOP-DI2J504 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
--               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ u_ila_0_stub.vhdl
-- Design      : u_ila_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a200tfbg676-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe1 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe2 : in STD_LOGIC_VECTOR ( 19 downto 0 );
    probe3 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe4 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe5 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe6 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe7 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe8 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe9 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe10 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe11 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe12 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe13 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe14 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe15 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe16 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe17 : in STD_LOGIC_VECTOR ( 19 downto 0 );
    probe18 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe19 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe20 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe21 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe22 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe23 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe24 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe25 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe26 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe27 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe28 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe29 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe30 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe31 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe32 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe33 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe34 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe35 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe36 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe37 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe38 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe39 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe40 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe41 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe42 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe43 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe44 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe45 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe46 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe47 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe48 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe49 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe50 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe51 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe52 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe53 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe54 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe55 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe56 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe57 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe58 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe59 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe60 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe61 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe62 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe63 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe64 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe65 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe66 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe67 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe68 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe69 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe70 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe71 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe72 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe73 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe74 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe75 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe76 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe77 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe78 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe79 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe80 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe81 : in STD_LOGIC_VECTOR ( 0 to 0 )
  );

end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture stub of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[3:0],probe1[31:0],probe2[19:0],probe3[31:0],probe4[3:0],probe5[3:0],probe6[31:0],probe7[31:0],probe8[7:0],probe9[31:0],probe10[7:0],probe11[7:0],probe12[7:0],probe13[31:0],probe14[31:0],probe15[31:0],probe16[7:0],probe17[19:0],probe18[3:0],probe19[31:0],probe20[31:0],probe21[7:0],probe22[31:0],probe23[31:0],probe24[31:0],probe25[31:0],probe26[31:0],probe27[31:0],probe28[31:0],probe29[31:0],probe30[31:0],probe31[31:0],probe32[31:0],probe33[31:0],probe34[31:0],probe35[31:0],probe36[31:0],probe37[31:0],probe38[31:0],probe39[31:0],probe40[31:0],probe41[31:0],probe42[31:0],probe43[31:0],probe44[31:0],probe45[31:0],probe46[31:0],probe47[31:0],probe48[31:0],probe49[31:0],probe50[31:0],probe51[31:0],probe52[31:0],probe53[0:0],probe54[0:0],probe55[0:0],probe56[0:0],probe57[0:0],probe58[0:0],probe59[0:0],probe60[0:0],probe61[0:0],probe62[0:0],probe63[0:0],probe64[0:0],probe65[0:0],probe66[0:0],probe67[0:0],probe68[0:0],probe69[0:0],probe70[0:0],probe71[0:0],probe72[0:0],probe73[0:0],probe74[0:0],probe75[0:0],probe76[0:0],probe77[0:0],probe78[0:0],probe79[0:0],probe80[0:0],probe81[0:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ila,Vivado 2019.2";
begin
end;
