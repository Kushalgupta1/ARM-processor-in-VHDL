library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

--Changes in stage 3 from 2-
--Changed name of S to Fset to highlight that update also depends on the cycle number in multi cycle
--If Fset is 1 then the instruction is DP, so removed instr_class input port
entity shifter is
Port (
   inp: in word;
	shift_type : in shift_rotate_op_type;
	shift_amount : in std_logic_vector(4 downto 0);
	carry_in: in std_logic;
	outp: out word;
	carry_out : out std_logic
);
end shifter;

architecture shifter_beh of shifter is

    component shift1 is
    Port (
    inp: in word;
        shift_type : in shift_rotate_op_type;
        carry_in: in std_logic;
        select_signal: in std_logic;
        outp: out word;
        carry_out : out std_logic
    );
    end component;	

    component shift2 is
    Port (
    inp: in word;
        shift_type : in shift_rotate_op_type;
        carry_in: in std_logic;
        select_signal: in std_logic;
        outp: out word;
        carry_out : out std_logic
    );
    end component;	

    component shift4 is
    Port (
    inp: in word;
        shift_type : in shift_rotate_op_type;
        carry_in: in std_logic;
        select_signal: in std_logic;
        outp: out word;
        carry_out : out std_logic
    );
    end component;	

    component shift8 is
    Port (
    inp: in word;
        shift_type : in shift_rotate_op_type;
        carry_in: in std_logic;
        select_signal: in std_logic;
        outp: out word;
        carry_out : out std_logic
    );
    end component;	

    component shift16 is
    Port (
    inp: in word;
        shift_type : in shift_rotate_op_type;
        carry_in: in std_logic;
        select_signal: in std_logic;
        outp: out word;
        carry_out : out std_logic
    );
    end component;	
	

	signal input_to_shift1, temp1_2, temp2_4, temp4_8, temp8_16, output_of_shift16: word;
	signal carry1_2, carry2_4, carry4_8, carry8_16: std_logic;
begin


	Reverser_start: for i in 0 to 31 generate
		input_to_shift1(i) <= inp(31 - i) when shift_type = LSL else inp(i);
	end generate Reverser_start;

	Reverser_end: for i in 0 to 31 generate
		outp(i) <= output_of_shift16(31 - i) when shift_type = LSL else output_of_shift16(i);
	end generate Reverser_end;

	comp_shift1: shift1 port map(input_to_shift1, shift_type, carry_in, shift_amount(0), temp1_2, carry1_2);
	comp_shift2: shift2 port map(temp1_2, shift_type, carry1_2, shift_amount(1), temp2_4, carry2_4);
	comp_shift4: shift4 port map(temp2_4, shift_type, carry2_4, shift_amount(2), temp4_8, carry4_8);
	comp_shift8: shift8 port map(temp4_8, shift_type, carry4_8, shift_amount(3), temp8_16, carry8_16);
	comp_shift16: shift16 port map(temp8_16, shift_type, carry8_16, shift_amount(4), output_of_shift16, carry_out);

end shifter_beh;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity shift1 is
Port (
   inp: in word;
	shift_type : in shift_rotate_op_type;
	carry_in: in std_logic;
	select_signal: in std_logic;
	outp: out word;
	carry_out : out std_logic
);
end shift1;	

architecture shift1_beh of shift1 is
	signal msb_outp : std_logic_vector(0 downto 0);
begin
	with select_signal select
		carry_out <= inp(0) when '1', 
				       carry_in when others;
	

		msb_outp <= inp(0 downto 0) when shift_type= RORrot else
					   "0" when shift_type = LSL or shift_type = LSR or (shift_type = ASR and inp(31) = '0') else
					   "1";
	
	with select_signal select
		outp <= inp when '0', 
			     msb_outp & inp(31 downto 1) when others;
	  

end shift1_beh;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity shift2 is
Port (
   inp: in word;
	shift_type : in shift_rotate_op_type;
	carry_in: in std_logic;
	select_signal: in std_logic;
	outp: out word;
	carry_out : out std_logic
);
end shift2;	

architecture shift2_beh of shift2 is
	signal msb_outp : std_logic_vector(1 downto 0);
begin
	with select_signal select
		carry_out <= inp(1) when '1', 
				       carry_in when others;
	

		msb_outp <= inp(1 downto 0) when shift_type= RORrot else
					   "00" when shift_type = LSL or shift_type = LSR or (shift_type = ASR and inp(31) = '0') else
					   "11";
	
	with select_signal select
		outp <= inp when '0', 
			     msb_outp & inp(31 downto 2) when others;
	  

end shift2_beh;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity shift4 is
Port (
   inp: in word;
	shift_type : in shift_rotate_op_type;
	carry_in: in std_logic;
	select_signal: in std_logic;
	outp: out word;
	carry_out : out std_logic
);
end shift4;	

architecture shift4_beh of shift4 is
	signal msb_outp : std_logic_vector(3 downto 0);
begin
	with select_signal select
		carry_out <= inp(3) when '1', 
				       carry_in when others;
	

		msb_outp <= inp(3 downto 0) when shift_type= RORrot else
					   "0000" when shift_type = LSL or shift_type = LSR or (shift_type = ASR and inp(31) = '0') else
					   "1111";
	
	with select_signal select
		outp <= inp when '0', 
			     msb_outp & inp(31 downto 4) when others;
	  

end shift4_beh;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity shift8 is
Port (
   inp: in word;
	shift_type : in shift_rotate_op_type;
	carry_in: in std_logic;
	select_signal: in std_logic;
	outp: out word;
	carry_out : out std_logic
);
end shift8;	

architecture shift8_beh of shift8 is
	signal msb_outp : std_logic_vector(7 downto 0);
begin
	with select_signal select
		carry_out <= inp(7) when '1', 
				       carry_in when others;
	

		msb_outp <= inp(7 downto 0) when shift_type= RORrot else
					   "00000000" when shift_type = LSL or shift_type = LSR or (shift_type = ASR and inp(31) = '0') else
					   "11111111";
	
	with select_signal select
		outp <= inp when '0', 
			     msb_outp & inp(31 downto 8) when others;
	  

end shift8_beh;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity shift16 is
Port (
   inp: in word;
	shift_type : in shift_rotate_op_type;
	carry_in: in std_logic;
	select_signal: in std_logic;
	outp: out word;
	carry_out : out std_logic
);
end shift16;	

architecture shift16_beh of shift16 is
	signal msb_outp : std_logic_vector(15 downto 0);
begin
	with select_signal select
		carry_out <= inp(15) when '1', 
				     carry_in when others;
	

		msb_outp <= inp(15 downto 0) when shift_type= RORrot else
					   "0000000000000000" when shift_type = LSL or shift_type = LSR or (shift_type = ASR and inp(31) = '0') else
					   "1111111111111111";
	
	with select_signal select
		outp <= inp when '0', 
			     msb_outp & inp(31 downto 16) when others;
	  

end shift16_beh;