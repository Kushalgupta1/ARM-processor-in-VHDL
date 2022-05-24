library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MyTypes.all;
use IEEE.NUMERIC_STD.ALL;

entity processor is
Port(
    CLK: in bit
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
    carry_in: in std_logic_vector(0 downto 0);
	res: out std_logic_vector(31 downto 0); --Outputs: result of operation, carry out
	carry_out: out std_logic
);
end component;

component DM is
port(
	CLK: in bit;
    addr: in std_logic_vector(5 downto 0); --one address port only as read and write never done together, word level addressing 
    write_en: in std_logic_vector(3 downto 0); --byte level write enable
    data_in: in std_logic_vector(31 downto 0); --write port
    data_out: out std_logic_vector(31 downto 0) --read port
);
end component;

component PM is
port(
    addr: in std_logic_vector(5 downto 0); --address port  
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
    instr_class : in instr_class_type; --Only DP instructions affect flags
    DP_subclass : in DP_subclass_type;  --multiply instructions not included
	S : in std_logic; --S bit
	carry_ALU, MSBop1, MSBop2: in std_logic; --carry bit, MSB bits of operands of ALU 
	--shift carry not included
	res_ALU: in word; --result of ALU
    Z, V, C, N: out std_logic
);
end component;

component PC is
Port (
	CLK: in bit;
	--pc_in: in word; --input program counter value
	cond: in boolean;  --whether the conditon provided by condition checker (based on condition field and flag values) is true or false
    instr_class : in instr_class_type;  --DP, DT or BRN
	offset: in std_logic_vector(23 downto 0);  --24 bit offset
    pc_out: out word
);
end component;

component ConditionChecker is
Port (
    Z, V, C, N: in std_logic;
    cond_field: in std_logic_vector(3 downto 0); --31 to 28 bits of insruction specifying the condition code
	res: out boolean  --res is true if the cond_field satisfies the appropriate flag requirements
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
signal op1, op2, res: std_logic_vector(31 downto 0) := X"00000000";
--signal op2, res: std_logic_vector(31 downto 0);
signal carry_in: std_logic_vector(0 downto 0) := "0";
signal alu_carry_out: std_logic;

signal DM_addr : std_logic_vector(5 DOWNTO 0);
signal DM_write_en : std_logic_vector(3 downto 0) := "0000";
SIGNAL DM_write_data : std_logic_vector(31 downto 0);
signal DM_read_data : std_logic_vector(31 DOWNTO 0);

signal PM_addr: std_logic_vector(5 downto 0);
signal PM_read_data: std_logic_vector(31 downto 0);

signal instr: word;
signal decoder_instr_class: instr_class_type;
signal decoder_operation : optype;
signal decoder_DP_subclass : DP_subclass_type;
signal decoder_DP_operand_src : DP_operand_src_type;
signal decoder_load_store : load_store_type;
signal decoder_DT_offset_sign : DT_offset_sign_type;

signal FlagUpdater_S: std_logic;
signal Z, V, C, N: std_logic;

--signal PC_in: word := X"00000000"; 
--signal PC_cond: boolean;  
signal PC_offset: std_logic_vector(23 downto 0);
signal PC_out: word := X"00000000";

signal ConditionChecker_cond_field: std_logic_vector(3 downto 0);
signal ConditionChecker_res: boolean; 

begin


    RF1: RF port map(CLK, reg_read_addr1, reg_read_addr2, reg_write_addr, reg_write_en, reg_write_data, reg_read_data1, reg_read_data2);

    ALU1: ALU port map(opcode, op1, op2, carry_in, res, alu_carry_out);

	DM1: DM port map(CLK, DM_addr, DM_write_en, DM_write_data, DM_read_data);

    PM1: PM port map(PM_addr, PM_read_data);

    Decoder1: Decoder port map(instr, decoder_instr_class, decoder_operation, decoder_DP_subclass, decoder_DP_operand_src, decoder_load_store, decoder_DT_offset_sign);

    FlagUpdater1: FlagUpdater port map(CLK, decoder_instr_class, decoder_DP_subclass, FlagUpdater_S, alu_carry_out, op1(31), op2(31), res, Z, V, C, N);

    PC1: PC port map(CLK, ConditionChecker_res, decoder_instr_class, PC_offset, PC_out);

    ConditionChecker1: ConditionChecker port map(Z, V, C, N, ConditionChecker_cond_field, ConditionChecker_res);

    carry_in(0) <= C;
    reg_read_addr1 <= instr(19 downto 16);
    reg_write_addr <= instr(15 downto 12);
    op1 <= reg_read_data1;
    DM_addr <= res(7 downto 2);
    DM_write_data <= reg_read_data2;
    PM_addr <= PC_out(7 downto 2);
    instr <= PM_read_data;
    FlagUpdater_S <= instr(20);
    PC_offset <= instr(23 downto 0);
    ConditionChecker_cond_field <= instr(31 downto 28);
    --PC_in <= PC_out; --to fetch new instruction

    --now set the write enables for RF and DM, read addr 2 and write data for RF, and opcode 2 for ALU

    --deciding read address 2 and write data for RF based on instr class
    with decoder_instr_class select
    reg_read_addr2 <= instr(3 downto 0)   when DP,
                      instr(15 downto 12) when others;

    --deciding write data for RF based on instr class
    with decoder_instr_class select
    reg_write_data <= res   when DP,
                      DM_read_data when others;

    --deciding write enable for DM
    DM_write_en <= "1111" when  decoder_instr_class = DT and decoder_load_store = store else 
                   "0000";

    --deciding write enable for RF
    reg_write_en <= '1' when decoder_instr_class = DP and (decoder_DP_subclass = arith or decoder_DP_subclass = logic) else
                    '1' when decoder_instr_class = DT and decoder_load_store = load else 
                    '0';

 
    --deciding opcode
    opcode <= decoder_operation when decoder_instr_class = DP else
              add when decoder_DT_offset_sign = plus else
              sub;

    --deciding op2 of ALU
    op2 <= reg_read_data2 when decoder_instr_class = DP and decoder_DP_operand_src = reg else
           X"000000"& instr(7 downto 0) when decoder_instr_class = DP and decoder_DP_operand_src = imm else
           X"00000" & instr(11 downto 0);

end pro_beh;