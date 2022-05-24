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
    	signal PM_space : type_mem := 
                                     (0 => X"E3A00008",
                                  1 => X"E3A01005",
                                  2 => X"E5801000",
                                  3 => X"E2811002",
                                  4 => X"E5801004",
                                  5 => X"E5902000",
                                  6 => X"E5903004",
                                  7 => X"E0434002",
                                  others => X"00000000"
                                  );
    --mov r0, #8
    --mov r1, #5
    --str r1, [r0]
    --add r1, r1, #2
    --str r1, [r0, #4]
    --ldr r2, [r0]
    --ldr r3, [r0, #4]
    --sub r4, r3, r2

    
begin
	data_out<= PM_space(to_integer(unsigned(addr))); --read from memory  
end pm_beh;