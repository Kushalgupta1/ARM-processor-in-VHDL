library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

--Data memory
entity Mem is
port(
	CLK: in bit;
    addr: in std_logic_vector(6 downto 0); --one address port only as read and write never done together, word level addressing 
    write_en: in std_logic_vector(3 downto 0); --byte level write enable
    data_in: in std_logic_vector(31 downto 0); --write port
    data_out: out std_logic_vector(31 downto 0) --read port
);
end Mem;

architecture mem_beh of Mem is

	type type_mem is array (0 to 127) of std_logic_vector(31 downto 0); --datatype for 128 words of memory
	--as same memory for both data and program, ensure that there is no overlap
	--in testcases, assumed that program occupies first 64 words in memory
	signal Mem_space : type_mem := 
                                 ( 0 => X"E3A00002",
									1 => X"E3E01003",
									2 => X"E1A02051",
									3 => X"E3A03007",
									4 => X"E1A04013",
									5 => X"E1A05033",
									6 => X"E1A06073",
									others => X"00000000"
									);

	-- mov r0, #2
	-- mvn r1, #3
	-- mov r2, r1, ASR r0 @r2 should contain 0xFFFFFFFF
	-- mov r3, #7
	-- mov r4, r3, LSL r0
	-- mov r5, r3, LSR r0
	-- mov r6, r3, ROR r0

begin
	data_out<= Mem_space(to_integer(unsigned(addr))); --read from memory 

--byte level write into memory on clock edge, write into the bytes whose enable is set of the word whose address is provided  
 	write_data : process (CLK) is
	begin
		if CLK = '1' then
			if write_en(0) = '1' then
				Mem_space(to_integer(unsigned(addr)))(7 downto 0) <= data_in(7 downto 0);
			end if;
			if write_en(1) = '1' then
				Mem_space(to_integer(unsigned(addr)))(15 downto 8) <= data_in(15 downto 8);	
			end if;
			if write_en(2) = '1' then
				Mem_space(to_integer(unsigned(addr)))(23 downto 16) <= data_in(23 downto 16);	
			end if;
			if write_en(3) = '1' then
				Mem_space(to_integer(unsigned(addr)))(31 downto 24) <= data_in(31 downto 24);
			end if;
		end if;
	end process write_data;  

end mem_beh;