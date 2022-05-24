library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity ConditionChecker is
Port (
    Z, V, C, N: in std_logic;
    cond_field: in std_logic_vector(3 downto 0); --31 to 28 bits of insruction specifying the condition code
	res: out boolean  --res is true if the cond_field satisfies the appropriate flag requirements
);
end ConditionChecker;

architecture cc_beh of ConditionChecker is

begin
	--only providing support for NE and EQ  and always true conditions
check_condition: process(Z, V, C, N, cond_field) is
	begin

		if cond_field = "0000" and Z = '1' then 
			res <= true;
		elsif cond_field = "0001" and Z = '0' then
			res <= true;
		elsif cond_field = "1110" or cond_field = "1111" then
			res <= true;
		else 
			res <= false;
		end if;

	end process check_condition;

end cc_beh;