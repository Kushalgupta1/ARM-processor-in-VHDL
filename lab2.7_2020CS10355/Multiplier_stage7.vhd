library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MyTypes.all;

--------Only update from stage 1 in stage 3 - carry_in made a std_logic instead of a size 1 vector------------
entity Multiplier is
port(
	op1: in std_logic_vector(31 downto 0); --Inputs: operands 1, 2 and 3 if accumulate, type of multiply instruction
	op2: in std_logic_vector(31 downto 0);
	op3: in std_logic_vector(63 downto 0);
	MULT_instr: MULT_instr_type;
	res: out std_logic_vector(63 downto 0) --Outputs: result of operation, carry out
	);
end Multiplier;

architecture Multiplier_beh of Multiplier is

	signal p_s: signed (65 downto 0);
	signal x1, x2: std_logic;
	signal res_temp: std_logic_vector(63 downto 0);
	
	begin
	
	with MULT_instr select
		x1 <= op1(31) when SMULL | SMLAL,
				'0' when others;
				
	with MULT_instr select 
		x2 <= op2(31) when SMULL | SMLAL,
				'0' when others;
	
	p_s <= signed (x1 & op1) * signed (x2 & op2);
	res_temp <= std_logic_vector(p_s (63 downto 0));
	
	with MULT_instr select 
		res <= res_temp when mul |umull | smull,
		       std_logic_vector(unsigned(res_temp) + unsigned(op3)) when others;
	
	
end Multiplier_beh;