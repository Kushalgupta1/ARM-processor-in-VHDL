library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity processor is
Port(
    CLK: in bit;
    reset: in bit
);
end processor; 

architecture pro_beh of processor is

component RF is
port(
	CLK: in bit;
    read_addr1: in std_logic_vector(3 downto 0); --two read address ports and one write address port
    read_addr2: in std_logic_vector(3 downto 0);
    write_addr: in std_logic_vector(3 downto 0);
    write_en: in std_logic; --write enable
    data_in: in std_logic_vector(31 downto 0); --write port
    data_out1: out std_logic_vector(31 downto 0); --read port
    data_out2: out std_logic_vector(31 downto 0)
);
end component;

component ALU is
port(
	opcode: in optype;
	op1: in std_logic_vector(31 downto 0); --Inputs: opcode specifying the DP instruction, operands 1 and 2, carry in 
	op2: in std_logic_vector(31 downto 0);
   carry_in: in std_logic;
	res: out std_logic_vector(31 downto 0); --Outputs: result of operation, carry out
	carry_out: out std_logic
);
end component;

component Mem is
port(
	CLK: in bit;
    addr: in std_logic_vector(6 downto 0); --one address port only as read and write never done together, word level addressing 
    write_en: in std_logic_vector(3 downto 0); --byte level write enable
    data_in: in std_logic_vector(31 downto 0); --write port
    data_out: out std_logic_vector(31 downto 0) --read port
);
end component;

component Decoder is
Port (
    instruction : in word;
    instr_class : out instr_class_type;
    operation : out optype;
    DP_subclass : out DP_subclass_type;
	 DT_instr : out DT_instr_type;
    DP_operand_src : out src_type;
    load_store : out load_store_type;
	 pre_post : out pre_post_type;
	 DT_write_back : out write_back_type;
    DT_offset_sign : out DT_offset_sign_type;
    DT_offset_src : out src_type;
    reg_shift_type : out shift_rotate_op_type;
    reg_shift_src : out src_type
);
end component;

component FlagUpdater is
Port (
	CLK: in bit;
   DP_subclass : in DP_subclass_type;  --multiply instructions not included
	Fset : in std_logic; --if this is 1 then at the rising edge of the clock, flags are updated
	carry_ALU, carry_shifter, MSBop1, MSBop2: in std_logic; --carry bit generated by ALU, carry bit generated by shifter, MSB bits of operands of ALU (after considering + operation for arith and comp subclass, for calculating V flag)
	res_ALU: in word; --result of ALU
   Z, V, C, N: out std_logic := '0'
);
end component;

component PC is
Port (
	CLK: in bit;
	pc_in: in word; --input program counter value
	write_en: std_logic;
    pc_out: out word := X"00000000" --actual program counter register
);
end component;

component ConditionChecker is
Port (
    Z, V, C, N: in std_logic;
    cond_field: in std_logic_vector(3 downto 0); --31 to 28 bits of insruction specifying the condition code
	res: out std_logic  --res is true if the cond_field satisfies the appropriate flag requirements
);
end component;

component shifter is
Port (
   inp: in word;
	shift_type : in shift_rotate_op_type;
	shift_amount : in std_logic_vector(4 downto 0);
	carry_in: in std_logic;
	outp: out word;
	carry_out : out std_logic
);
end component;

component PMconnect is
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
end component;

signal reg_read_addr1: std_logic_vector(3 downto 0);
signal reg_read_addr2: std_logic_vector(3 downto 0);
signal reg_write_addr: std_logic_vector(3 downto 0);
signal reg_write_en: std_logic := '0';
signal reg_write_data: std_logic_vector(31 downto 0);
signal reg_read_data1: std_logic_vector(31 downto 0);
signal reg_read_data2: std_logic_vector(31 downto 0);

signal opcode: optype;
signal op1, op2, alu_res: std_logic_vector(31 downto 0) := X"00000000";
--signal op2, alu_res: std_logic_vector(31 downto 0);
signal alu_carry_in: std_logic;
signal alu_carry_out: std_logic;

signal Mem_addr : word;
signal Mem_write_en : std_logic_vector(3 downto 0) := "0000";
signal Mem_write_data : word;
signal Mem_read_data : word;

--signal instr: word;
signal decoder_instr_class: instr_class_type;
signal decoder_operation : optype;
signal decoder_DP_subclass : DP_subclass_type;
signal decoder_DT_instr : DT_instr_type;
signal decoder_DP_operand_src : src_type;
signal decoder_load_store : load_store_type;
signal decoder_pre_post : pre_post_type;
signal decoder_DT_write_back : write_back_type;
signal decoder_DT_offset_sign : DT_offset_sign_type;
signal decoder_DT_offset_src : src_type;
signal decoder_reg_shift_type : shift_rotate_op_type;
signal decoder_reg_shift_src : src_type;


signal Fset: std_logic; --if true, flags are updated at the rising edge
signal Z, V, C, N: std_logic;
signal op1_forFlagUpdater, op2_forFlagUpdater: std_logic_vector(31 downto 0);

signal pc_in: word;
signal pc_write_en: std_logic;
signal pc_out: word;

signal ConditionChecker_cond_field: std_logic_vector(3 downto 0);
signal ConditionChecker_res: std_logic; 

signal shifter_input : word;
signal shifter_shift_type : shift_rotate_op_type;
signal shifter_shift_amount : std_logic_vector(4 downto 0);
signal shifter_carry_in : std_logic;
signal shifter_output : word;
signal shifter_carry_out : std_logic;

signal PMconnect_MW : nibble;
signal PMconnect_Min : word;
signal PMconnect_Rin : word;

signal instr_S_bit: std_logic;
signal dp_imm_const: byte;
signal dt_imm_const: std_logic_vector(11 downto 0);
signal pc_offset: std_logic_vector(23 downto 0);
signal state: integer:= 1; --start from the first state
signal IR, DR, A, B, Res, X, D: word;


begin


    RF1: RF port map(CLK, reg_read_addr1, reg_read_addr2, reg_write_addr, reg_write_en, reg_write_data, reg_read_data1, reg_read_data2);

    ALU1: ALU port map(opcode, op1, op2, alu_carry_in, alu_res, alu_carry_out);

	 Mem1: Mem port map(CLK, Mem_addr(8 downto 2), Mem_write_en, Mem_write_data, Mem_read_data);

    Decoder1: Decoder port map(IR, decoder_instr_class, decoder_operation, decoder_DP_subclass, decoder_DT_instr, decoder_DP_operand_src, decoder_load_store, decoder_pre_post, decoder_DT_write_back, decoder_DT_offset_sign, decoder_DT_offset_src, decoder_reg_shift_type, decoder_reg_shift_src);
	 
    FlagUpdater1: FlagUpdater port map(CLK, decoder_DP_subclass, Fset, alu_carry_out, shifter_carry_out, op1_forFlagUpdater(31), op2_forFlagUpdater(31), alu_res, Z, V, C, N);

    PC1: PC port map(CLK, pc_in, pc_write_en, pc_out);

    ConditionChecker1: ConditionChecker port map(Z, V, C, N, ConditionChecker_cond_field, ConditionChecker_res);
	 
	 shifter1: shifter port map(shifter_input, shifter_shift_type, shifter_shift_amount, shifter_carry_in, shifter_output, shifter_carry_out);
	 
	 PMconnect1 : PMconnect port map(decoder_DT_instr, state, Mem_addr(1 downto 0), B, DR, PMconnect_Rin, PMconnect_Min, PMconnect_MW);

    reg_read_addr1 <= IR(19 downto 16);
    Mem_write_data <= PMConnect_Min;
	 Mem_write_en <= PMConnect_MW;
    pc_in<= alu_res(29 downto 0) & "00";
    ConditionChecker_cond_field <= IR(31 downto 28);
    
    instr_S_bit <= IR(20);
    pc_offset <= IR(23 downto 0);
    dp_imm_const <= IR(7 downto 0);
    dt_imm_const <= IR(11 downto 0);
	 
	 
	 shifter_carry_in <= C; --carry flag given as carry_in 
	 --deciding the input, shift type, shift amount for shifter depending on source of operand/offset and source of shift amount
	 shifter_input <= X"00000" & IR(11 downto 0) when (decoder_instr_class = DTtype01 and decoder_DT_offset_src = imm) else --when DTtype01 has imm offset
	                  X"000000" & IR(11 downto 8) & IR(3 downto 0) when (decoder_instr_class = DTtype00 and decoder_DT_offset_src = imm) else --when DTtype00 has imm offset
							X"000000" & IR(7 downto 0) when (decoder_instr_class = DP and decoder_DP_operand_src = imm) else --in DP, imm offset
							B; --reg has operand/offset
	 
	 shifter_shift_type <= LSL when (decoder_instr_class = DTtype01 and decoder_DT_offset_src = imm) else --when DTtype01 has imm offset, LSL #0 is given
	                       LSL when decoder_instr_class = DTtype00 else --for DTtype00 , always LSL #0 given
	                       RORrot when (decoder_instr_class = DP and decoder_DP_operand_src = imm) else --in DP, imm offset, rotate given
								  
	                       decoder_reg_shift_type; --reg has operand/offset for DP or DTtype01
								  
								  
								 
	 shifter_shift_amount <= "00000" when (decoder_instr_class = DTtype01 and decoder_DT_offset_src = imm) else --when DTtype01 has imm offset, LSL #0 is given
	                         "00000" when decoder_instr_class = DTtype00 else --for DTtype00 , always LSL #0 given
									 IR(11 downto 8) & "0" when (decoder_instr_class = DP and decoder_DP_operand_src = imm) else --in DP, imm offset, rotate by two times the given amount
									 X(4 downto 0) when (decoder_instr_class = DP and decoder_DP_operand_src = reg and decoder_reg_shift_src = reg) or (decoder_instr_class = DTtype01 and decoder_DT_offset_src = reg and decoder_reg_shift_src = reg) else
									 IR(11 downto 7);
	

    --deciding read address 2 for RF
    reg_read_addr2 <= IR(3 downto 0) when state = 2 else
                      IR(15 downto 12) when state = 4 else
                      IR(11 downto 8); --to read shift amount from register in state 10

    --deciding write data for RF
    with state select
    reg_write_data <= Res   when 6 | 7 | 8,
                      PMconnect_Rin when others; --when in state 9, use this as write data

	 --deciding write address for RF
	 with state select
	 reg_write_addr <= IR(19 downto 16) when 7 | 8, --for write_back
	                   IR(15 downto 12) when others;
	 
    --deciding write enable for RF
    reg_write_en <= '1' when (state = 6 and (decoder_DP_subclass = arith or decoder_DP_subclass = logic)) else
	                 '1' when state = 9 else
						  '1' when (state = 7 or state = 8) and (decoder_DT_write_back = write_back or decoder_pre_post = post) else
                    '0';

    --deciding opcode
    opcode <= decoder_operation when state = 3 else
              add when state = 4 and decoder_DT_offset_sign = plus else
              sub when state = 4 and decoder_DT_offset_sign = minus else
              adc;

    --deciding op1
    --word address of PC taken
    with state select
    op1 <= A when 3 | 4,
           "00" & pc_out(31 downto 2) when others;

    --deciding op2 of ALU
    --can be register or immediate for DP, imm for DT, PC word offset or -1 for state 5 or 0 for state 1 PC update
    op2 <= D when state = 3 or state = 4 else
           X"00" & pc_offset when state = 5 and IR(23) = '0' else
           X"11" & pc_offset when state = 5 and IR(23) = '1' else
           X"00000000"; --state 1 pc update
           
    
    --deciding operands to pass to flagUpdater, 2's complement wherever negative value is passed
    with IR(24 downto 21) select
    op1_forFlagUpdater <= std_logic_vector(unsigned(not(op1)) + to_unsigned(1, 32)) when "0011" | "0111", --rsb, rsc
                          op1 when others;
    with IR(24 downto 21) select
    op2_forFlagUpdater <= std_logic_vector(unsigned(not(op2)) + to_unsigned(1, 32)) when "0010" | "0110" | "1010", --sub, sbc, cmp
                          op2 when others;
    --selecting carry in for ALU
    --carry in is 1 for PC update
    with state select
    alu_carry_in <= '1' when 1 | 5,
                 C when others;

    --deciding PC write enable
    with state select
    pc_write_en <= '1' when 1 | 5,
                   '0' when others;

    --deciding memory address (this is a 32 bit address, from this 8 downto 2 bits are passed on to the memory (hence, now byte level addressing is followed in instructions) and 1 downto 0 bits are passed onto PMConnect to decide the byte/hword level load/store
    Mem_addr <= pc_out when state = 1 or state = 4 else
                Res when decoder_pre_post = pre else --pre indexing
					 A; --post indexing
    
    --deciding whether to update flags or not
    Fset <= '1' when state = 3 and instr_S_bit = '1' else '0';
    
    FSM: process(CLK, reset) is
    --In stage 5, added 2 more states, now 11 states total.
    --state 10: reached if the second operand/offset is a register and the shift amount is specified by a register. The shift amount is stored in register X at the end of this stage. State 10 transitions to state 11. 
    --state 11: the shift amount is available (either in X or immediate) and the result of the shifter module is stored in register D at the end of this stage.

    --FSM has 9 states (as given in lec 10 slide 38), state transitions take place at the rising edge of clock, each state generates control signals (select signals for various multiplexers) such as 
    --write enable for RF, Mem, PC 
    --whether to update Flags 
    --value of carry_in for ALU 
    --opcode and operands of ALU 
    --write data for RF 
    --second read address of RF, address of Memory
    
    --STATES-
    --1 - Load current instruction in register, PC updated by 4
    --2 - Load A and B wih register values

	 --10 - If shift amount for DP/DT given by a register, then fetch the contents of the shift amount in X register
	 --11 - shifted operand/offset of DP/DT loaded in D register
    --3 - DP instruction, load alu result in Res, update flags if required
    --6 - next step in DP, store Res in Register file

    --4 - DT instruction, load Res with alu result computing address of Memory for load/store
    --7 - if str, store contents of B in memory
    --8 - if ldr, store memory contents in DR
    --9 - next in ldr, store DR contents in RF

    --5 - if conditon true, update PC with offset, if condition false, add 0 at this step
	 
    begin
        if CLK = '1' then
            case state is
                when 1 => 
                IR <= Mem_read_data;
                state <= 2;
                
                when 2 =>
                A <= reg_read_data1;
                B <= reg_read_data2;
                if ConditionChecker_res = '1' then
					 
                    if decoder_instr_class = BRN then
                        state <= 5;
                    elsif (decoder_instr_class = DP and decoder_DP_operand_src = reg and decoder_reg_shift_src = reg) then 
								state <= 10;
						  elsif (decoder_instr_class = DTtype01 and decoder_DT_offset_src = reg and decoder_reg_shift_src = reg) then
                        state <= 10; --when reg has the shift amount (obviously reg has the the operand/offset)
                    else  --either reg has operand/offset and no shift/shift amount is immediate or immediate operand/offset
                        state <= 11;
                    end if;
						  
                else 
                    state <= 1;
                end if;
                    
                when 10 =>
                X <= reg_read_data2; --fetch the shift amount from the register
                state <= 11;

                when 11 =>
                D <= shifter_output;
                case decoder_instr_class is
                    when DP => state <= 3;
                    when others => state <= 4; --when DT, goto state 4
                end case;

                when 3 => 
                Res <= alu_res;
                state <= 6;

                when 4 =>
                B <= reg_read_data2;
                Res <= alu_res;
                case decoder_load_store is 
                    when store => state <= 7;
                    when load => state <= 8;
                end case;

                when 5 =>
                state <= 1;

                when 6 =>
                state <= 1;

                when 7 =>
                state <= 1;

                when 8 =>
                DR <= Mem_read_data;
                state <= 9;

                when 9 =>
                state <= 1;
            
                when others =>
                state <= 1;
            end case;
        end if;

    if reset = '1' then
        state <= 1;
    end if;

    end process FSM;

end pro_beh;