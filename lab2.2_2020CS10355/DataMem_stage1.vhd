library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

--Data memory
entity DM is
port(
	CLK: in bit;
    addr: in std_logic_vector(5 downto 0); --one address port only as read and write never done together, word level addressing 
    write_en: in std_logic_vector(3 downto 0); --byte level write enable
    data_in: in std_logic_vector(31 downto 0); --write port
    data_out: out std_logic_vector(31 downto 0) --read port
);
end DM;

architecture dm_beh of DM is

	type type_mem is array (0 to 63) of std_logic_vector(31 downto 0); --datatype for 64 bytes of memory
    signal DM_space : type_mem; --uninitialised
    
begin
	data_out<= DM_space(to_integer(unsigned(addr))); --read from memory 

--byte level write into memory on clock edge, write into the bytes whose enable is set of the word whose address is provided  
 	write_data : process (CLK) is
	begin
		if CLK = '1' then
			if write_en(0) = '1' then
				DM_space(to_integer(unsigned(addr)))(7 downto 0) <= data_in(7 downto 0);
			end if;
			if write_en(1) = '1' then
				DM_space(to_integer(unsigned(addr)))(15 downto 8) <= data_in(15 downto 8);	
			end if;
			if write_en(2) = '1' then
				DM_space(to_integer(unsigned(addr)))(23 downto 16) <= data_in(23 downto 16);	
			end if;
			if write_en(3) = '1' then
				DM_space(to_integer(unsigned(addr)))(31 downto 24) <= data_in(31 downto 24);
			end if;
		end if;
	end process write_data;  

end dm_beh;