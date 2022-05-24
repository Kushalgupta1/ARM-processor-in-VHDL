library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

--PROGRAM COUNTER that updates PC appropriately at every clock cycle
entity PC is
Port (
	CLK: in bit;
	--pc_in: in word; --input program counter value
	cond: in boolean;  --whether the conditon provided by condition checker (based on condition field and flag values) is true or false
    instr_class : in instr_class_type;  --DP, DT or BRN
	offset: in std_logic_vector(23 downto 0);  --24 bit offset
    pc_out: out word
);
end PC;

architecture pc_beh of PC is
    signal pc : word := X"00000000";

begin
    
 	update_pc : process (CLK) is
		variable pc_internal : word;
	begin
		pc_internal := pc;
		if CLK = '1' then
			if (instr_class = BRN) and cond then 
			    pc_internal := std_logic_vector(signed(pc_internal) + signed(offset & "00") + 8);
			else 
			    pc_internal := std_logic_vector(signed(pc_internal) + 4);
			end if;
		end if;
		pc <= pc_internal;
		pc_out <= pc_internal;
	end process update_pc;  

end pc_beh;