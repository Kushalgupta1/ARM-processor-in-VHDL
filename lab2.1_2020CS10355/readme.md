# Lab Assignment 2, Stage 1: Design and testing of basic modules 

# The module set includes ALU, Register File, Program Memory and Data Memory.

### Kushal Kumar Gupta

### 2020CS10355

### 



#### Files, entities and Architectures:

1. ###### ALU_stage1.vhd contains the entity ALU

   ALU:    ALU circuit which takes as input-

   ​	I.)opcode: one of the following 16 DP opcode of type optype. 

   ​	optype is an enumerated type with DP opcodes:   

   ​      			`andop, eor, sub, rsb, add, adc, sbc, rsc, tst, teq, cmp, cmn, orr, mov, bic, mvn`

   ​	II.)op1, op2: the two operands,  as 32-bit std_logic_vectors

   ​	III.)carry_in: carry input as a 1-bit std_logic_vector

   And outputs:

   ​	I.) res: the 32-bit std_logic_vector result of the operation specified by the opcode on op1 and op2

   ​	II.) carry_out: carry output as a std_logic



​	For specific implementation of each operation see the architecture alu_beh of ALU.

​	Implementation considerations: 

​		--No shifting or rotating of operands supported

​		--For 8 opcodes which do not affect the carry (`and, orr, eor, bic, mov, mvn, tst, teq`), carry_out has been assigned carry_in

​		--Uses 2's complement subtraction

​		--Uses 33 bit std_logic_vector to store temporary results and obtain carry output in operations that require addition/subtraction  (`add, sub, rsb, adc, sbc, rsc, cmp, cmn`)



###### 2. RegFile_stage1.vhd contains the entity RF

RF:  Register File with register memory as an array of 16 std_logic_vectors of 32-bits 

Inputs-

​	I.)CLK: clock as a single bit

​	II.)read_addr1, read_addr2: two read address ports,  as 4-bit std_logic_vectors

​	III.)write_addr: one write address port as 4-bit std_logic_vector

​	IV.)write_en: write enable, write operation performed only when this is active

​	V.)data_in: 32-bit std_logic_vector one data port for 1-word write operation in Register File in address corresponding to write_addr

Outputs:

​	I.)data_out1, data_out2: 32-bit std_logic_vector two data ports for 1-word read operation from Register File from the addresses corresponding to read_addr1 and read_addr2 respectively



For implementation, see the architecture rf_beh of RF.

Implementation considerations: 

​	--Two data outputs on which contents of the array elements selected by read addresses are continuously available. 

​	--If write enable is active, at rising clock edge the input data gets written in the array element selected by write address. 

​	--Word- level addressing and only word level R/W supported



###### 3. DataMemory_stage1.vhd contains the entity DM

DM:  Data Memory with memory implemented as an array of 64 std_logic_vectors of 32-bits 

Inputs-

​	I.)CLK: clock as a single bit

​	II.)addr:  32-bit std_logic_vector one address port, for both read/write 

​	III.)write_en: std_logic_vector(3 downto 0), 4 bits for byte level write operation

​	IV.)data_in: 32-bit std_logic_vector one data port for 1-word write operation in memory in address corresponding to addr

Outputs:

​	I.)data_out: 32-bit std_logic_vector one data port for 1-word read operation from memory from the address corresponding to addr



For implementation, see the architecture dm_beh of DM.

Implementation considerations: 

​	--Data_out has contents of the array elements selected by addr continuously available. 

​	--Has 4 bit write enable to support byte level write operation in memory. At the rising edge of the clock, to the corresponding bits set in write_en the bytes written into the word selected by the addr. 

​	--Word- level addressing

​	--Word-level read operation from memory supported



###### 4. ProgramMemory_stage1.vhd contains the entity PM

PM:  Program Memory with memory implemented as an array of 64 std_logic_vectors of 32-bits 

Inputs-

​	I.)addr: one read address port,  as 32-bit std_logic_vectors

Outputs:

​	I.)data_out: 32-bit std_logic_vector one data port for 1-word read operation from Program Memory from the address corresponding to addr



For implementation, see the architecture pm_beh of PM.

Implementation considerations: 

​	--The data output on which contents of the array elements selected by read addresses is continuously available. 

​	--Word- level addressing

​	--Word-level read operation from memory supported

​	--Read Only Memory, write operation not supported



###### 5. DPopcodes_stage1.vhd

Has optype, which is an enumerated type with DP opcodes:     `andop, eor, sub, rsb, add, adc, sbc, rsc, tst, teq, cmp, cmn, orr, mov, bic, mvn`



###### 6. Testbench.vhd

Has test cases to check the modules implemented above. Makes DUTs of these components and provides different input signals. CLK has time period of 30 ns.



###### 7. Design.vhd

Dummy entity to run the simulation.



###### 8. run.do

Specifies the FPGA to be used for synthesis and report of the synthesis.


<div style="page-break-after: always;"></div>
#### How to use:

On edaplayground.com,  upload testbench.vhd and run.do in the left column, and ALU_stage1.vhd, RegFile_stage1.vhd, DataMemory_stage1.vhd, ProgramMemory_stage1.vhd and DPopcodes_stage1.vhd. Copy contents in design.vhd as given in the file. Select   Testbench + Design as VHD. Then, for

###### 1.)Simulation

Type testbench in the Top entity. Select Aldec Riviera Pro 2020.04 simulator to simulate the design. Set 2000 ns as the run time and select the EPWave option. Then Save and Run the simulation to get waves of the signals defined in these modules.



###### 2.)Synthesis

Copy the VHDL file of the module you want to synthesise into design.vhd. (Only design.vhd entities are synthesised)

Then, select Mentor Precision 2021.1 to synthesise. Select netlist option to view the Verilog description. Then Save and Run to get the synthesis result. We get the report containing the resource table specifying number of IOs, LUTs, CLB slices, ports, nets, etc. used to implement this module in the given FPGA specified by run.do.


<div style="page-break-after: always;"></div>
#### Results:


###### 1.) EPWave (Simulation): 

Can see the input and output signals of different modules against the clock.

I.) ALU

![](epwave1.png)



II.)Register File

![](ep4.png)

III.) Data Memory

![epwave2](epwave2.png)



IV.) Program Memory

![ep3](ep3.png)


<div style="page-break-after: always;"></div>

###### 2.) Resource Table (Synthesis)

Can see the resources used by the different module implementations on given FPGA.

I.) ALU

![](r1.png)

<div style="page-break-after: always;"></div>

II.)Register File

![ep3](r2.png)

<div style="page-break-after: always;"></div>

III.) Data Memory

![epwave2](r3.png)



<div style="page-break-after: always;"></div>

IV.) Program Memory

![](r4.png)

