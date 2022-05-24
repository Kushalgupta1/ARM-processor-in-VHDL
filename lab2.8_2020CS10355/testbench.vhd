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
	input_port : in std_logic_vector(8 downto 0);
    reset: in bit
);
end component;

signal CLK : bit := '0';
signal input_port : std_logic_vector(8 downto 0) := "0" & X"00";
signal reset : bit := '0';

begin
	CLK <= not CLK after 5 ns;
    DUT_processor: processor port map(CLK, input_port, reset);
    testInPort: process is
        begin
            wait for 126 ns;
            reset <= '1';
            wait for 2 ns;
            reset <= '0';
            wait for 1000 ns;
    end process testInPort;
end tb;