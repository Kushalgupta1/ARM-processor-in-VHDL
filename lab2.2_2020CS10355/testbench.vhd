-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity testbench is
-- empty
end testbench; 

architecture tb of testbench is

component processor is
Port(
    CLK: in bit
);
end processor;

signal CLK : bit := '0';

begin
	CLK <= not CLK after 10 ns;
    DUT_processor: processor port map(CLK);
end tb;