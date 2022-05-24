library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

--Program memory
entity PM is
port(
    addr: in std_logic_vector(5 downto 0); --address port  
    data_out: out std_logic_vector(31 downto 0) --read port
);
end PM;

architecture pm_beh of PM is

	type type_mem is array (0 to 63) of std_logic_vector(31 downto 0); --datatype for 64 bytes of memory
	signal PM_space : type_mem := (others=>(others=>'0')); --initialise entire space to 0
    
begin
	data_out<= PM_space(to_integer(unsigned(addr))); --read from memory  
end pm_beh;