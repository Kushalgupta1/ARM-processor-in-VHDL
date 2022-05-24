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
    DP_operand_src : out DP_operand_src_type;
    load_store : out load_store_type;
    DT_offset_sign : out DT_offset_sign_type
);
end component;

component FlagUpdater is
Port (
	CLK: in bit;
    DP_subclass : in DP_subclass_type;  --multiply instructions not included
	FSet : in std_logic; --S bit
	carry_ALU, MSBop1, MSBop2: in std_logic; --carry bit, MSB bits of operands of ALU 
	--shift carry not included
	res_ALU: in word; --result of ALU
    Z, V, C, N: out std_logic
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
signal carry_in: std_logic;
signal alu_carry_out: std_logic;

signal Mem_addr : std_logic_vector(6 DOWNTO 0);
signal Mem_write_en : std_logic_vector(3 downto 0) := "0000";
signal Mem_write_data : std_logic_vector(31 downto 0);
signal Mem_read_data : std_logic_vector(31 DOWNTO 0);

--signal instr: word;
signal decoder_instr_class: instr_class_type;
signal decoder_operation : optype;
signal decoder_DP_subclass : DP_subclass_type;
signal decoder_DP_operand_src : DP_operand_src_type;
signal decoder_load_store : load_store_type;
signal decoder_DT_offset_sign : DT_offset_sign_type;

signal Fset: std_logic; --if true, flags are updated at the rising edge
signal Z, V, C, N: std_logic;

signal pc_in: word;
signal pc_write_en: std_logic;
signal pc_out: word;

signal ConditionChecker_cond_field: std_logic_vector(3 downto 0);
signal ConditionChecker_res: std_logic; 

signal instr_S_bit: std_logic;
signal dp_imm_const: byte;
signal dt_imm_const: std_logic_vector(11 downto 0);
signal pc_offset: std_logic_vector(23 downto 0);
signal state: integer:= 1; --start from the first state
signal IR, DR, A, B, Res: word;

begin


    RF1: RF port map(CLK, reg_read_addr1, reg_read_addr2, reg_write_addr, reg_write_en, reg_write_data, reg_read_data1, reg_read_data2);

    ALU1: ALU port map(opcode, op1, op2, carry_in, alu_res, alu_carry_out);

	Mem1: Mem port map(CLK, Mem_addr, Mem_write_en, Mem_write_data, Mem_read_data);

    Decoder1: Decoder port map(IR, decoder_instr_class, decoder_operation, decoder_DP_subclass, decoder_DP_operand_src, decoder_load_store, decoder_DT_offset_sign);

    FlagUpdater1: FlagUpdater port map(CLK, decoder_DP_subclass, Fset, alu_carry_out, op1(31), op2(31), alu_res, Z, V, C, N);

    PC1: PC port map(CLK, pc_in, pc_write_en, pc_out);

    ConditionChecker1: ConditionChecker port map(Z, V, C, N, ConditionChecker_cond_field, ConditionChecker_res);

    reg_read_addr1 <= IR(19 downto 16);
    reg_write_addr <= IR(15 downto 12);
    Mem_write_data <= B;
    pc_in<= alu_res(29 downto 0) & "00";
    ConditionChecker_cond_field <= IR(31 downto 28);
    
    instr_S_bit <= IR(20);
    pc_offset <= IR(23 downto 0);
    dp_imm_const <= IR(7 downto 0);
    dt_imm_const <= IR(11 downto 0);

    --deciding read address 2 for RF
    reg_read_addr2 <= IR(3 downto 0) when state = 2 and decoder_instr_class = DP else
                      IR(15 downto 12);

    --deciding write data for RF
    with state select
    reg_write_data <= Res   when 6,
                      DR when others;

    --deciding write enable for RF
    reg_write_en <= '1' when (state = 6 and (decoder_DP_subclass = arith or decoder_DP_subclass = logic)) or state = 9 else
                    '0';

    --deciding write enable for Mem
    with state select
    Mem_write_en <= "1111" when 7,
                   "0000" when others;

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
    --can be register or immediate for DP, imm for DT, PC word offset or -1 for state 5 depending whether condition field is satified or false or 0 for state 1 PC update
    op2 <= B when state = 3 and decoder_DP_operand_src = reg else
           X"000000"& dp_imm_const when state = 3 and decoder_DP_operand_src = imm and IR(7) = '0' else
           X"111111"& dp_imm_const when state = 3 and decoder_DP_operand_src = imm and IR(7) = '1' else
           X"00000" & dt_imm_const when state = 4 else
           X"00" & pc_offset when state = 5 and IR(23) = '0' and ConditionChecker_res = '1' else
           X"11" & pc_offset when state = 5 and IR(23) = '1' and ConditionChecker_res = '1' else
           X"FFFFFFFF" when state = 5 and ConditionChecker_res = '0' else
           X"00000000";
           
    --selecting carry in for ALU
    --carry in is 1 for PC update
    with state select
    carry_in <= '1' when 1 | 5,
                 C when others;

    --deciding PC write enable
    with state select
    pc_write_en <= '1' when 1 | 5,
                   '0' when others;

    --deciding memory address
    with state select 
    Mem_addr <= pc_out(8 downto 2) when 1 | 4,
               Res(6 downto 0) when others; --Unlike stage 2, now the instruction is assumed to follow word level addressing, i.e str r1, [r0, 1] will store contents of r1 in memory in word number r0 + 1
    
    --deciding whether to update flags or not
    Fset <= '1' when state = 3 and instr_S_bit = '1' else '0';
    
    FSM: process(CLK, reset) is
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
                case decoder_instr_class is
                    when DP => state <= 3;
                    when DT => state <= 4;
                    when BRN => state <= 5;
                    when others => state <= 1;
                end case;

                when 3 => 
                Res <= alu_res;
                state <= 6;

                when 4 =>
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