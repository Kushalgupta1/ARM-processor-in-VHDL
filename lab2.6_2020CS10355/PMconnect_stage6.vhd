library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity PMconnect is
Port(
	 DT_instr : in DT_instr_type;
	 state : in integer;
	 ADR10 : in std_logic_vector(1 downto 0);
	 Rout : in word;
	 Mout : in word;
	 Rin : out word;
	 Min : out word;
	 MW : out nibble
);
end PMconnect; 

architecture PMconnect_beh of PMconnect is

	
	
begin
	 connect: process(DT_instr, state, ADR10, Rout, Mout) is
	 begin
		case state is 
			when 7 =>
			case DT_instr is
				when STR => 
				Min <= Rout;
				MW <= "1111";
				Rin <= X"00000000";
				
				when STRH =>
				Min <= Rout(15 downto 0)  & Rout(15 downto 0);
				case ADR10 is
					when "00" => MW <= "0011";
					when others => MW <= "1100";
				end case;
				Rin <= X"00000000";
				
				when others => --STRB
				Min <= Rout(7 downto 0) & Rout(7 downto 0) & Rout(7 downto 0) & Rout(7 downto 0);
				case ADR10 is
					when "00" => MW <= "0001";
					when "01" => MW <= "0010";
					when "10" => MW <= "0100";
					when others => MW <= "1000";
				end case;
				Rin <= X"00000000";	
			end case;
				 
			when 9 =>
			case DT_instr is
				when LDR => 
				Rin <= Mout;
				Min <= X"00000000";
				MW <= X"0";
				
				when LDRH =>
				case ADR10 is 
					when "00" => Rin <= X"0000" & Mout(15 downto 0);
					when others => Rin <= X"0000" & Mout(31 downto 16);
				end case;
				Min <= X"00000000";
				MW <= X"0";
				
				when LDRSH =>
				case ADR10 is
					when "00" => 
					case Mout(15) is
						when '0' => Rin <= X"0000" & Mout(15 downto 0);
						when others => Rin <= X"FFFF" & Mout(15 downto 0);
					end case;
					
					when others =>
					case Mout(31) is
						when '0' => Rin <= X"0000" & Mout(31 downto 16);
						when others => Rin <= X"FFFF" & Mout(31 downto 16);
					end case;					
				end case;	
				Min <= X"00000000";
				MW <= X"0";
				
				when LDRB =>
				case ADR10 is
					when "00" => Rin <= X"000000" & Mout(7 downto 0);
					when "01" => Rin <= X"000000" & Mout(15 downto 8);
					when "10" => Rin <= X"000000" & Mout(23 downto 16);
					when others => Rin <= X"000000" & Mout(31 downto 24);
				end case;	
				Min <= X"00000000";
				MW <= X"0";
				
				when others => --LDRSB
				case ADR10 is
					when "00" => 
					case Mout(7) is
						when '0' => Rin <= X"000000" & Mout(7 downto 0);
						when others => Rin <= X"FFFFFF" & Mout(7 downto 0);
					end case;
					
					when "01" => 
					case Mout(15) is
						when '0' => Rin <= X"000000" & Mout(15 downto 8);
						when others => Rin <= X"FFFFFF" & Mout(15 downto 8);
					end case;
					
					when "10" => 
					case Mout(23) is
						when '0' => Rin <= X"000000" & Mout(23 downto 16);
						when others => Rin <= X"FFFFFF" & Mout(23 downto 16);
					end case;
					
					when others =>
					case Mout(31) is
						when '0' => Rin <= X"000000" & Mout(31 downto 24);
						when others => Rin <= X"FFFFFF" & Mout(31 downto 24);
					end case;					
				end case;					 
				Min <= X"00000000";
				MW <= X"0";
			end case;
		 
			when others =>
			Min <= X"00000000";
			MW <= X"0";
			Rin <= X"00000000";
			
		end case;
	end process connect;

end PMconnect_beh;