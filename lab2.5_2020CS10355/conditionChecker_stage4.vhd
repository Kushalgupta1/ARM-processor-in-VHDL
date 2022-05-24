library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

--changes from stage 2 - res made a std_logic instead of boolean to view it in EPWave
entity ConditionChecker is
Port (
    Z, V, C, N: in std_logic;
    cond_field: in std_logic_vector(3 downto 0); --31 to 28 bits of insruction specifying the condition code
	res: out std_logic  --res is true if the cond_field satisfies the appropriate flag requirements
);
end ConditionChecker;

architecture cc_beh of ConditionChecker is

begin
	--only providing support for NE and EQ  and always true conditions
check_condition: process(Z, V, C, N, cond_field) is
	begin
		 case cond_field is
		 -- EQ
		 when "0000" => 
		 	if Z = '1' then res <= '1'; 
			else res <= '0' ;
			end if;
		 --NE
		 when "0001" => 
			if Z = '0' then res <= '1';
			else res <= '0';
			end if;
		 --CS | HS
		 when "0010" =>
			if C = '1'then res <= '1';
			else res <= '0';
			end if;
		 --CC | LO
		 when "0011" =>
			if C = '0' then res <= '1';
			else res <= '0';
			end if;
		 --MI
		 when "0100" =>
			if N = '1' then res <= '1';
			else res <= '0';
			end if;
		 --PL
		 when "0101" =>
			if N = '0' then res <= '1';
			else res <= '0';
			end if;
		 --VS
		 when "0110" =>
			if V = '1' then res <= '1';
			else res <= '0';
			end if;
		 --VC
		 when "0111" =>
			if V = '0' then res <= '1';
			else res <= '0';
			end if;
		 --HI
		 when "1000" =>
			if C = '1' and Z ='0' then res <= '1';
			else res <= '0';
			end if;
		 --LS
		 when "1001" =>
			if C = '0' or Z = '1' then res <= '1';
			else res <= '0';
			end if;
		 --GE
		 when "1010" =>
			if N = V then res <= '1';
			else res <= '0';
			end if;
		 --LT
		 when "1011" =>
			if N /= V then res <= '1';
			else res <= '0';
			end if;
		 --GT
		 when "1100" =>
			if Z = '0' and (N = V) then res <='1';
			else res <= '0';
			end if;
		 --LE
		 when "1101" =>
			if Z = '1' or (N /= V) then res <='1';
			else res <= '0';
			end if;
		 --AL
		 when "1110" => res <= '1';
		 --Always
		 when "1111" => res <= '1';
		--irrelevant
		 when others => res <= '0';
		 end case;

	end process check_condition;

end cc_beh;