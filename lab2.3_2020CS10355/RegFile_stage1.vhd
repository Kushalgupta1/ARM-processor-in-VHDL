library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

--Register file
entity RF is
port(
	CLK: in bit;
    read_addr1: in std_logic_vector(3 downto 0); --two read address ports and one write address port
    read_addr2: in std_logic_vector(3 downto 0);
    write_addr: in std_logic_vector(3 downto 0);
    write_en: in std_logic; --write enable
    data_in: in std_logic_vector(31 downto 0); --write port
    data_out1: out std_logic_vector(31 downto 0); --read ports corresponding to read addr 1 and 2 respectively
    data_out2: out std_logic_vector(31 downto 0)
);
end RF;

architecture rf_beh of RF is

	type type_RF is array (0 to 15) of std_logic_vector(31 downto 0); --datatype for 64 bytes of memory
    signal RF_space : type_RF; --uninitialised
	--signal Mem_space : internal_data := (others=>(others=>'0'));
    
begin
	data_out1<= RF_space(to_integer(unsigned(read_addr1))); --read from memory 
    data_out2<= RF_space(to_integer(unsigned(read_addr2)));

--byte level write into memory on clock edge, write into the bytes whose enable is set of the word whose address is provided  
 	write_data : process (CLK) is
	begin
		if CLK = '1' then
			if write_en = '1' then
				RF_space(to_integer(unsigned(write_addr))) <= data_in;				
			end if;
		end if;
	end process write_data;  

end rf_beh;