library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

--PROGRAM COUNTER that updates PC appropriately at every clock cycle
entity PC is
Port (
	CLK: in bit;
	pc_in: in word; --input program counter value
	write_en: std_logic;
    pc_out: out word := X"00000000" --actual program counter register
);
end PC;

architecture pc_beh of PC is

begin
 	update_pc : process (CLK) is
	begin
		if CLK = '1' and write_en = '1' then
			pc_out <= pc_in;
		end if;
	end process update_pc;  

end pc_beh;