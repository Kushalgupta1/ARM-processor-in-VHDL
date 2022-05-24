library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MyTypes.all;

--------Only update from stage 1 in stage 3 - carry_in made a std_logic instead of a size 1 vector------------
entity ALU is
port(
	opcode: in optype;
	op1: in std_logic_vector(31 downto 0); --Inputs: opcode specifying the DP instruction, operands 1 and 2, carry in 
	op2: in std_logic_vector(31 downto 0);
    carry_in: in std_logic;
	res: out std_logic_vector(31 downto 0); --Outputs: result of operation, carry out
	carry_out: out std_logic --no ; after the last port declaration
	);
end ALU;

--basic ALU, performs the 16 DP operations and updates the ALU carry when required
architecture alu_beh of ALU is
	begin

	operations : process (opcode, op1, op2, carry_in) is 

    variable res_temp: std_logic_vector(32 downto 0);
    variable op1_temp: std_logic_vector(32 downto 0);
    variable op2_temp: std_logic_vector(32 downto 0);
    variable one_int: std_logic_vector(32 downto 0) := "000000000000000000000000000000001";  --vector to represent 1 
    
	begin
	--implement operations and, orr, eor, bic, mov, mvn, tst, teq that do not require expanding to 33 bits to store the carry of operation
    --in all these operations, ALU carry is unaffected, and assigned carry_in    
    	if (opcode= andop) or (opcode= tst) then
			res <= op1 and op2;
			carry_out <= carry_in;
		elsif opcode= orr then
			res <= op1 or op2;
			carry_out <= carry_in;
		elsif (opcode= eor) or (opcode= teq) then
			res <= op1 xor op2;
			carry_out <= carry_in;
 		elsif opcode= bic then
			res <= op1 and not(op2);
			carry_out <= carry_in;           
 		elsif opcode= mov then
			res <= op2;
			carry_out <= carry_in;
		elsif opcode= mvn then
			res <= not(op2);
			carry_out <= carry_in;
	--implement operations add, sub, rsb, adc, sbc, rsc, cmp, cmn that do require expanding to 33 bits to store the carry of operation
    --in all these operations, ALU carry is affected    
        elsif (opcode= add) or (opcode= cmn) then
        	op1_temp := "0"&op1;
            op2_temp := "0"&op2;            
            res_temp := std_logic_vector(unsigned(op1_temp)+unsigned(op2_temp));
            carry_out <= res_temp(32); --33rd bit is the carry out
            res <= res_temp(31 downto 0); --removing the 33rd bit in final result            
        elsif opcode=adc then
            op1_temp := "0"&op1;
            op2_temp := "0"&op2; 
        	res_temp := std_logic_vector(unsigned(op1_temp)+carry_in);
            res_temp := std_logic_vector(unsigned(res_temp)+unsigned(op2_temp));
            carry_out <= res_temp(32);
            res <= res_temp(31 downto 0);
        elsif (opcode= sub) or (opcode= cmp) then
         	op1_temp := "0"&op1;
            op2_temp := "1"&op2; 
            op2_temp := not(op2_temp); --op2_temp now contains complement of op2 (ignoring 33rd bit)
            res_temp := std_logic_vector(unsigned(op1_temp)+unsigned(one_int));
            res_temp := std_logic_vector(unsigned(res_temp)+unsigned(op2_temp));
            carry_out <= res_temp(32);
            res <= res_temp(31 downto 0);
        elsif opcode= sbc then
         	op1_temp := "0"&op1;   
            op2_temp := "1"&op2; 
            op2_temp := not(op2_temp); --op2_temp now contains complement of op2 (ignoring 33rd bit)
            res_temp := std_logic_vector(unsigned(op1_temp)+carry_in);
            res_temp := std_logic_vector(unsigned(res_temp)+unsigned(op2_temp));
            carry_out <= res_temp(32);
            res <= res_temp(31 downto 0);
        elsif opcode= rsb then
         	op2_temp := "0"&op2;   
            op1_temp := "1"&op1; 
            op1_temp := not(op1_temp); --op1_temp now contains complement of op1 (ignoring 33rd bit)
            res_temp := std_logic_vector(unsigned(op1_temp)+unsigned(one_int));
            res_temp := std_logic_vector(unsigned(res_temp)+unsigned(op2_temp));
            carry_out <= res_temp(32);
            res <= res_temp(31 downto 0);
        elsif opcode= rsc then
         	op2_temp := "0"&op2;   
            op1_temp := "1"&op1; 
            op1_temp := not(op1_temp); --op1_temp now contains complement of op1 (ignoring 33rd bit)
            res_temp := std_logic_vector(unsigned(op1_temp)+carry_in);
            res_temp := std_logic_vector(unsigned(res_temp)+unsigned(op2_temp));
            carry_out <= res_temp(32);
            res <= res_temp(31 downto 0); 
	    else --error, opcode doesn't match
   		    res<= X"00000000";
            carry_out <= '0';
		end if;
        
	end process operations;
    
end alu_beh;
