library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity FlagUpdater is
Port (
	CLK: in bit;
    instr_class : in instr_class_type; --Only DP instructions affect flags
    DP_subclass : in DP_subclass_type;  --multiply instructions not included
	S : in std_logic; --S bit
	carry_ALU, MSBop1, MSBop2: in std_logic; --carry bit, MSB bits of operands of ALU 
	--shift carry not included
	res_ALU: in word; --result of ALU
    Z, V, C, N: out std_logic
);
end FlagUpdater;

architecture fu_beh of FlagUpdater is

begin

	--assuming no shift, update flags
 	update_flags : process (CLK) is
	variable overflow : boolean;
	begin

		if CLK = '1' and S = '1' and instr_class = DP then
			if DP_subclass = arith or DP_subclass = comp then
					if res_ALU = X"00000000" then
						Z <= '1';
					else 
						Z <= '0';
					end if;
					C <= carry_ALU;
					N <= res_ALU(31);

					overflow:= ( (MSBop1 = '1') and (MSBop2 = '1') and not(res_ALU(31) = '1') ) or ( not(MSBop1 = '1') and not(MSBop2 = '1') and (res_ALU(31) = '1') );
					if overflow then 
						V <= '1'; 
					else 
						V <= '0';
					end if;
			elsif DP_subclass = comp  or DP_subclass = test then
				if res_ALU = X"00000000" then
					Z <= '1';
				else 
					Z <= '0';
				end if;
				N <= res_ALU(31);
			end if;
		end if;
	end process update_flags;  

end fu_beh;