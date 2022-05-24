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
	--system area is 0 to 63rd word, user area is 64 to 127th word
	--Input port is given address of 63rd word
	--as same memory for both data and program, ensure that there is no overlap
	--in testcases, assumed that program occupies 64 to 95th word (first half of user memory)
	

signal Mem_space : type_mem := 
							( 0 => X"EA000006",
							2 => X"EA00000C",
							8 => X"E3A0EC01",
							9 => X"E6000011",
							16 => X"E3A00000",
							17 => X"E59000FC",
							18 => X"E6000011",
                            64 => X"E3E00102",
							65 => X"E3A01001",
							66 => X"E0902001",
							67 => X"63B03004",
							68 => X"E0233002",
							69 => X"E3B04000",
							70 => X"11130003",
							others => X"00000000");

	--64 mov r0, #0x7fffffff
	--65 mov r1, #1
	--66 adds r2, r0, r1
	--67 movvss r3, #4 @overflow is set, hence condition true
	--68 eoral r3, r3, r2 @al is always true
	--69 mvns r4, #0xffffffff
	--70 tstne r3, r3 @condition false


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