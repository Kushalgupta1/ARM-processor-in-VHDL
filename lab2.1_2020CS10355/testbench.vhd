-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;
use work.MyTypes.all;

entity testbench is
-- empty
end testbench; 

architecture tb of testbench is

component RF is
port(
	CLK: in bit;
    read_addr1: in std_logic_vector(3 downto 0); --two read address ports and one write address port
    read_addr2: in std_logic_vector(3 downto 0);
    write_addr: in std_logic_vector(3 downto 0);
    write_en: in std_logic; --write enable
    data_in: in std_logic_vector(31 downto 0); --write port
    data_out1: out std_logic_vector(31 downto 0); --read port
    data_out2: out std_logic_vector(31 downto 0);
);
end RF;

component ALU is
port(
	opcode: in optype;
	op1: in std_logic_vector(31 downto 0); --Inputs: opcode specifying the DP instruction, operands 1 and 2, carry in 
	op2: in std_logic_vector(31 downto 0);
    carry_in: in std_logic_vector(0 downto 0);
	res: out std_logic_vector(31 downto 0); --Outputs: result of operation, carry out
	carry_out: out std_logic:= '0';
);
end ALU;

component DM is
port(
	CLK: in bit;
    addr: in std_logic_vector(5 downto 0); --one address port only as read and write never done together, word level addressing 
    write_en: in std_logic_vector(3 downto 0); --byte level write enable
    data_in: in std_logic_vector(31 downto 0); --write port
    data_out: out std_logic_vector(31 downto 0); --read port
);
end DM;

component PM is
port(
    addr: in std_logic_vector(5 downto 0); --address port  
    data_out: out std_logic_vector(31 downto 0); --read port
);
end PM;

signal CLK : bit := '1';

signal reg_read_add1: std_logic_vector(3 downto 0) := "0000";
signal reg_read_add2: std_logic_vector(3 downto 0) := "0001";
signal reg_write_add: std_logic_vector(3 downto 0):= "0000";
signal reg_write_en: std_logic := '0';
signal reg_write_data: std_logic_vector(31 downto 0):="11100000000000000000000000000011";
signal reg_read_data1: std_logic_vector(31 downto 0);
signal reg_read_data2: std_logic_vector(31 downto 0);

signal opcode: optype;
signal op1, op2, res: std_logic_vector(31 downto 0);
signal carry_in: std_logic_vector(0 downto 0);
signal carry_out: std_logic;

SIGNAL DM_addr : std_logic_vector(5 DOWNTO 0):="100101";
signal DM_write_en : std_logic_vector(3 downto 0):="0001";
SIGNAL DM_write_data : std_logic_vector(31 downto 0):="00000000000000001001001011110000";
SIGNAL DM_read_data : std_logic_vector(31 DOWNTO 0);

signal PM_addr: std_logic_vector(5 downto 0):="100010";
signal PM_read_data: std_logic_vector(31 downto 0);



begin
	clk <= not clk after 15 ns;
    DUT_RF: RF port map(CLK, reg_read_add1, reg_read_add2, reg_write_add, reg_write_en, reg_write_data, reg_read_data1,  reg_read_data2);
    DUT_ALU: ALU port map(opcode, op1, op2, carry_in, res, carry_out);
	DUT_DM: DM port map(CLK, DM_addr, DM_write_en, DM_write_data, DM_read_data);
    DUT_PM: PM port map(PM_addr, PM_read_data);


   	process
    begin
 
        --testing RegisterFile, by doing writes and then checking the read ouputs    
        reg_write_en<='1';
        wait for 50 ns;
        --reg_read_data1 should read reg_write_data from reg_read_add1 0000
        assert(reg_read_data1="11100000000000000000000000000011") report("RF read/write failed") severity error;
        
        reg_write_add<="0001";
        reg_write_data <= "10000000000000000000000000000011";
        wait for 50 ns;
         --reg_read_data2 should read reg_write_data from reg_read_add2 0001
        assert(reg_read_data2 ="10000000000000000000000000000011") report("RF read/write failed") severity error;
        
        reg_write_en<='0'; 
        reg_write_data <= "10000000000000000000000000000000";
        wait for 50 ns;
        --reg_read_data2 should not change
        assert(reg_read_data2 ="10000000000000000000000000000011") report("RF read/write failed") severity error;
        

        --testing 16 operations of ALU
        --andop
        op1 <= "11111111000000001111111100000000";
        op2 <= "11000000111111110000000001111111";
        opcode <= andop;
        wait for 50 ns;
        assert(res= (op1 and op2)) report("andop operation failed in ALU") severity error;
        --orr
        op1 <= "11111111000000001111111100000000";
        op2 <= "11000000111111110000000001111111";
        opcode <= orr;
        wait for 50 ns;
        assert(res= (op1 or op2)) report("orr operation failed in ALU") severity error;             
        --eor
        op1 <= "11111111000000001111111100000000";
        op2 <= "11000000111111110000000001111111";
        opcode <= eor;
        wait for 50 ns;
        assert(res= (op1 xor op2)) report("eor operation failed in ALU") severity error;             
        --bic
        op1 <= "11111111000000001111111100000000";
        op2 <= "11000000111111110000000001111111";
        opcode <= bic;
        wait for 50 ns;
        assert(res= (op1 and not(op2))) report("bic operation failed in ALU") severity error;  
        --mov
        op1 <= "11111111000000001111111100000000";
        op2 <= "11000000111111110000000001111111";
        opcode <= mov;
        wait for 50 ns;
        assert(res= op2) report("mov operation failed in ALU") severity error;          --mvn
        op1 <= "11111111000000001111111100000000";
        op2 <= "11000000111111110000000001111111";
        opcode <= mvn;
        wait for 50 ns;
        assert(res= not(op2)) report("mvn operation failed in ALU") severity error;             
        --tst
        op1 <= "11111111000000001111111100000000";
        op2 <= "11000000111111110000000001111111";
        opcode <= tst;
        wait for 50 ns;
        assert(res= (op1 and op2)) report("tst operation failed in ALU") severity error;    
         --teq
        op1 <= "11111111000000001111111100000000";
        op2 <= "11000000111111110000000001111111";
        opcode <= teq;
        wait for 50 ns;
        assert(res= (op1 xor op2)) report("teq operation failed in ALU") severity error;        
         

		carry_in <= "1";
        --add
        op1 <= "00000000000000000000000000000010";
        op2 <= "00000000000000000000000000000011";
        opcode <= add;
        wait for 50 ns;
        assert(res="00000000000000000000000000000101" and carry_out='0') 		report("add operation failed in ALU") severity error;
        op1 <= "10000000000000000000000000000010";
        op2 <= "10000000000000000000000000000011";   
        wait for 50 ns;
        assert(res="00000000000000000000000000000101" and carry_out='1')
report("add operation failed in ALU") severity error;

        --adc
        opcode <= adc;
        wait for 50 ns;
        assert(res="00000000000000000000000000000110" and carry_out='1') report("adc operation failed in ALU") severity error;

        --sub
        op1 <= "00000000000000000000000000000010";
        op2 <= "00000000000000000000000000000001";
        opcode <= sub;
        wait for 50 ns;
        assert(res="00000000000000000000000000000001" and carry_out='1') report("sub operation failed in ALU") severity error;
        
        --rsb
        op1 <= "00000000000000000000000000000001";
        op2 <= "00000000000000000000000000000010";
        opcode <= rsb;
        wait for 50 ns;
        assert(res="00000000000000000000000000000001" and carry_out='1') report("rsb operation failed in ALU") severity error;

        --sbc
        op1 <= "00000000000000000000000000000010";
        op2 <= "00000000000000000000000000000001";
        carry_in<= "0";
        opcode <= sbc;
        wait for 50 ns;
        assert(res="00000000000000000000000000000000" and carry_out='1') report("sbc operation failed in ALU") severity error;
        
        --rsc
        op1 <= "00000000000000000000000000000001";
        op2 <= "00000000000000000000000000000010";
        carry_in<= "0";
        opcode <= rsc;
        wait for 50 ns;
        assert(res="00000000000000000000000000000000" and carry_out='1') report("rsc operation failed in ALU") severity error;
        
        --cmp
        op1 <= "01010101000010101001111010111111";
        op2 <= "01111010101010101011101010101011";
        opcode <= cmp;
        wait for 50 ns;
        assert(carry_out='0') report("Fail cmp") severity error;
        
        --cmn
        op1 <= "10000000000000000000000000000010";
        op2 <= "10000000000000000000000000000011";  
        opcode <= cmn;
        wait for 50 ns;
        assert(res="00000000000000000000000000000101" and carry_out='1')
report("cmn operation failed in ALU") severity error;

        
        --testing Data Memory, perform byte level writes and read the memory.
    	wait for 50 ns;
        assert(DM_read_data(7 downto 0)="11110000") report("Fail Data Memory R/W") severity error;
        DM_write_en(0)<='0';
        DM_write_en(1)<='1';
        wait for 50 ns;
		assert(DM_read_data(15 downto 0)="1001001011110000") report("Fail Data Memory R/W") severity error;  
        
        --testing Program Memory, entire memory should be initialised to 0 
        assert(PM_read_data="00000000000000000000000000000000") report("Failed PM initialisation") severity error;
    end process;
end tb;