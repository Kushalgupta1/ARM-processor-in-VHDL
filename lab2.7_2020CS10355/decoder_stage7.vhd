library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity Decoder is
Port (
    instruction : in word;
    instr_class : out instr_class_type;
    operation : out optype;
    DP_subclass : out DP_subclass_type;
	 DT_instr : out DT_instr_type;
	 MULT_instr: out MULT_instr_type;
    DP_operand_src : out src_type;
    load_store : out load_store_type;
	 pre_post : out pre_post_type;
	 DT_write_back : out write_back_type;
    DT_offset_sign : out DT_offset_sign_type;
    DT_offset_src : out src_type;
    reg_shift_type : out shift_rotate_op_type;
    reg_shift_src : out src_type
);
end Decoder;

architecture Behavioral of Decoder is
    type oparraytype is array (0 to 15) of optype;
    constant oparray : oparraytype :=
    (andop, eor, sub, rsb, add, adc, sbc, rsc, tst, teq, cmp, cmn, orr, mov, bic, mvn);

begin
	--for 00 F field, DP if either bit 25 is 1 (immediate op2) or bit 25 is 0 and atleast one of bit 4 and 7 is 0, MULT when both bit 4 and 7 are 1 and SH is 00, DT when both bit 4 and 7 are 1 and SH is 01, 10 or 11				  
    instr_class <= DTtype01 when instruction (27 downto 26) = "01" else
                    DP when instruction (27 downto 25) = "001" else
	                DP when instruction (27 downto 26) = "00" and (instruction (4) = '0' or instruction(7) = '0') else
					MULT when instruction (27 downto 26) = "00" and instruction (6) = '0' and instruction(5) = '0' else
					DTtype00 when instruction (27 downto 26) = "00" else
                   BRN when instruction (27 downto 26) = "10" else
						 none;
	--Bit 20 - load /store type
	--Bit 22 - byte/word in 01 DP, imm/reg in 00 DT
	--Bit 25 - imm/reg in 01 DT
	--Bit 23 - offset sign
	--Bit 24 - pre/post indexing
	 DT_instr <= STR when instruction (27 downto 26) = "01" and instruction (22) = '0' and instruction (20) = '0' else
					 STRB when instruction (27 downto 26) = "01" and instruction (22) = '1' and instruction (20) = '0' else			 
					 STRH when instruction (27 downto 26) = "00" and instruction (20) = '0' and instruction(6) = '0' and instruction(5) = '1' else		 
					 LDR when instruction (27 downto 26) = "01" and instruction (22) = '0' and instruction (20) = '1' else		 
					 LDRB when instruction (27 downto 26) = "01" and instruction (22) = '1' and instruction (20) = '1' else		 
					 LDRSB when instruction (27 downto 26) = "00" and instruction(6) = '1' and instruction(5) = '0' else		 
					 LDRH when instruction (27 downto 26) = "00" and instruction (20) = '1' and instruction(6) = '0' and instruction(5) = '1' else		 
					 LDRSH when instruction (27 downto 26) = "00" and instruction(6) = '1' and instruction(5) = '1' else
					 invalidDT;
--bit 23 - short or long, bit 21 - accumulate or not, bit 22 - unsigned or signed
	 MULT_instr <= MUL when instruction(23) = '0' and instruction(21) = '0' else
	             MLA when instruction(23) = '0' and instruction(21) = '1' else
                UMULL when instruction(23) = '1' and instruction(21) = '0' and instruction(22) = '0' else
                UMLAL when instruction(23) = '1' and instruction(21) = '1' and instruction(22) = '0' else
                SMULL when instruction(23) = '1' and instruction(21) = '0' and instruction(22) = '1' else
                SMLAL when instruction(23) = '1' and instruction(21) = '1' and instruction(22) = '1' else
                invalidMULT;				  
	 
    operation <= oparray (to_integer(unsigned (instruction (24 downto 21))));

    with instruction (24 downto 22) select
        DP_subclass <= arith when "001" | "010" | "011",
                       logic when "000" | "110" | "111", --mov and mvn are also considered in the logic subclass
                       comp when "101",
                       test when others;

    DP_operand_src <= reg when instruction (25) = '0' else imm;
	 
    load_store <= load when instruction (20) = '1' else store;
	 pre_post <= pre when instruction(24) = '1' else post;
	 DT_write_back <= write_back when instruction(21) = '1' else no_write_back;
    DT_offset_sign <= plus when instruction (23) = '1' else minus;
	 
	 

    --whether register specifies the offset or 12 bit immediate
    DT_offset_src <= reg when (instruction (27 downto 26) = "01" and instruction(25) = '1') or (instruction (27 downto 26) = "00" and instruction(22) = '0') else 
							imm;
    --if register is the operand of DP/ offset of DT, what is the shift type
    with instruction (6 downto 5) select   
    reg_shift_type <= LSL when "00",
                      LSR when "01",
                      ASR when "10",
                      RORrot when others; 
    --if register is the operand of DP/ offset of DT, is the shift amount given by a register or is a 5 bit immediate
    reg_shift_src <= reg when instruction(4) = '1' else imm;

end Behavioral;