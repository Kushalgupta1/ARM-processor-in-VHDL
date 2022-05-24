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
    CLK: in bit;
    reset: in bit
);
end component;

signal CLK : bit := '0';
signal reset : bit := '0';

begin
	CLK <= not CLK after 5 ns;
    DUT_processor: processor port map(CLK, reset);
end tb;