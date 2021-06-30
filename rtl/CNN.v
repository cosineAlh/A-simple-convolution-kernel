`timescale 1ns / 1ns
module CNN(
	input clk,
	input rst,
	
	input start_conv,              //start signal
	output reg end_conv,           //end signal
	
	input [1:0] ci,                //input channels
	input [1:0] co,                //output numbers
	
	output [31:0] I_ram_addr,      //input address
    input [8*8-1:0] I_ram_dout,        //input
        
    output [31:0] W_ram_addr,      //weight address
    input [8*8-1:0] W_ram_dout,        //weight
        
    output [31:0] O_ram_addr,      //output address
    output [24:0] O_ram_din,       //output
    output reg O_wren              //one output can be get
);

integer N,M;                       //N is channel;M is number

//to choose the value of N and M
always @*
begin
    case(ci)//synopsys full_case
    2'b00:N=8;
    2'b01:N=16;
    2'b10:N=32;
    2'b11:N=64;
    endcase
    
    case(co)//synopsys full_case
    2'b00:M=8;
    2'b01:M=16;
    2'b10:M=32;
    2'b11:M=64;
    endcase
end

//parameter N = 8;
//parameter M = 8;
parameter R = 64;
parameter C = 64;
parameter S = 1;
parameter K = 4;
parameter Rprime = R*S-K+1;
parameter Cprime = C*S-K+1;
parameter sys_kernel = 2;           //size of systolic array

//RAM Controller
reg [24:0] O_din=0;
reg O_wren_next=0;

reg [31:0] W_addr=0, W_addr_next=0 ,W_key=0, W_key_next=0;
reg [31:0] counter=0;
reg [31:0] I_i_addr=0, I_i_addr_next=0;
reg [31:0] I_i_key=0, I_i_key_next=0;
reg [31:0] I_j_addr=0, I_j_addr_next=0;
reg [31:0] I_n_addr=0, I_n_addr_next=0;
reg [31:0] I_addr=0,O_addr=0;

wire [8*8-1:0] I_dout, W_dout;
//buffers
reg [8*8-1:0] I_dout1=0, I_dout2=0, I_dout3=0, I_dout4=0, I_dout5=0, I_dout6=0, I_dout7=0, I_dout8=0;
reg [8*8-1:0] W_dout1=0, W_dout2=0, W_dout3=0, W_dout4=0, W_dout5=0, W_dout6=0, W_dout7=0, W_dout8=0;
reg [8*8-1:0] I_dout1_next=0, I_dout2_next=0, I_dout3_next=0, I_dout4_next=0, I_dout5_next=0, I_dout6_next=0, I_dout7_next=0, I_dout8_next=0;
reg [8*8-1:0] W_dout1_next=0, W_dout2_next=0, W_dout3_next=0, W_dout4_next=0, W_dout5_next=0, W_dout6_next=0, W_dout7_next=0, W_dout8_next=0;

integer j;

assign I_ram_addr = I_addr;
assign I_dout = I_ram_dout;

assign W_ram_addr = W_addr;
assign W_dout = W_ram_dout;

assign O_ram_addr = O_addr;

//use RELU function to active the output
RELU relu_inst(O_din,O_ram_din);

//determind output address
always @(posedge clk)
begin
    if(rst)
        O_addr <= 0;
    else
    if(O_wren)
        begin
            O_addr <= O_addr + 1;
            counter <= counter + 1;
        end
     
    if (counter == Rprime*Cprime)
        counter <= 0;
end

//PE Archiecture (Data path)
genvar i;
reg [24:0] S_in[0:K*K*sys_kernel/4-1];
reg [7:0] W_in[0:K*K*sys_kernel/4-1], X_in[0:K*K*sys_kernel/4-1];
wire [24:0] S_out[0:K*K*sys_kernel/4-1];
generate 
	for (i = 0; i < K*K*sys_kernel/4; i = i + 1)
        begin
            PE PE_inst(clk, S_in[i], W_in[i], X_in[i], S_out[i]);
        end
endgenerate

reg [4:0] state=0, state_next=0;
reg [31:0] cur_addr1=0, cur_addr1_next=0;
reg [31:0] cur_addr2=0, cur_addr2_next=0;
reg [31:0] cur_addr3=0, cur_addr3_next=0;
reg [31:0] cur_addr4=0, cur_addr4_next=0;
reg [31:0] cur_addr5=0, cur_addr5_next=0;
reg [31:0] cur_addr6=0, cur_addr6_next=0;
reg [31:0] cur_addr7=0, cur_addr7_next=0;
reg [31:0] cur_addr8=0, cur_addr8_next=0;
reg [31:0] global_addr=0, global_addr_next=0;
reg global_start=0,global_start_next=0;

//assign values for all wires and regs
always @(posedge clk)
begin
	if (rst)
		begin
			state <= 0;
			
			W_addr <= 0;
			W_key <= 0;
			
			I_i_addr <= 0;
			I_j_addr <= 0;
			I_n_addr <= 0;
			I_i_key  <= 0;
			
			cur_addr1 <= 0;
			cur_addr2 <= 0;
			cur_addr3 <= 0;
			cur_addr4 <= 0;
			cur_addr5 <= 0;
			cur_addr6 <= 0;
			cur_addr7 <= 0;
			cur_addr8 <= 0;
			
			I_dout1_next <= 0;W_dout1_next <= 0;
			I_dout2_next <= 0;W_dout2_next <= 0;
			I_dout3_next <= 0;W_dout3_next <= 0;
			I_dout4_next <= 0;W_dout4_next <= 0;
			I_dout5_next <= 0;W_dout5_next <= 0;
			I_dout6_next <= 0;W_dout6_next <= 0;
			I_dout7_next <= 0;W_dout7_next <= 0;
			I_dout8_next <= 0;W_dout8_next <= 0;
			
			global_addr <= 0;
			global_start <= 0;
											
			O_wren <= 0;
		end
	else
		begin
			state <= state_next;
			
			W_addr <= W_addr_next;
			W_key <= W_key_next;
			
			I_i_addr <= I_i_addr_next;
			I_i_key  <= I_i_key_next;
			I_j_addr <= I_j_addr_next;
			I_n_addr <= I_n_addr_next;
			
			cur_addr1 <= cur_addr1_next;
			cur_addr2 <= cur_addr2_next;
			cur_addr3 <= cur_addr3_next;
			cur_addr4 <= cur_addr4_next;
			cur_addr5 <= cur_addr5_next;
			cur_addr6 <= cur_addr6_next;
			cur_addr7 <= cur_addr7_next;
			cur_addr8 <= cur_addr8_next;
			
			I_dout1_next <= I_dout1;W_dout1_next <= W_dout1;
			I_dout2_next <= I_dout2;W_dout2_next <= W_dout2;
			I_dout3_next <= I_dout3;W_dout3_next <= W_dout3;
			I_dout4_next <= I_dout4;W_dout4_next <= W_dout4;
			I_dout5_next <= I_dout5;W_dout5_next <= W_dout5;
			I_dout6_next <= I_dout6;W_dout6_next <= W_dout6;
			I_dout7_next <= I_dout7;W_dout7_next <= W_dout7;
			I_dout8_next <= I_dout8;W_dout8_next <= W_dout8;
			
			global_addr <= global_addr_next;
			global_start <= global_start_next;

			O_wren <= O_wren_next;
		end
end

//determind the outputs
always @(posedge clk)
begin
    //Output
	if(global_addr == 0)
	   O_din <= S_out[K*K*sys_kernel/4-1];
	else
       O_din <= O_din+S_out[K*K*sys_kernel/4-1];
end

//Main
always @*
begin
    //basic address flow
	state_next = state;
	end_conv = 0;
	
	W_addr_next = W_addr;
	W_key_next = W_key;
	
	I_i_addr_next = I_i_addr;
	I_i_key_next = I_i_key;
	I_j_addr_next = I_j_addr;
	I_n_addr_next = I_n_addr;
	
	I_addr = I_n_addr*R*C+(I_i_addr)*R+(I_j_addr);     //Input address
	
	cur_addr1_next = cur_addr1;
	cur_addr2_next = cur_addr2;
	cur_addr3_next = cur_addr3;
	cur_addr4_next = cur_addr4;
	cur_addr5_next = cur_addr5;
	cur_addr6_next = cur_addr6;
	cur_addr7_next = cur_addr7;
	cur_addr8_next = cur_addr8;
	
	I_dout1 = I_dout1_next;W_dout1 = W_dout1_next;
    I_dout2 = I_dout2_next;W_dout2 = W_dout2_next;
    I_dout3 = I_dout3_next;W_dout3 = W_dout3_next;
    I_dout4 = I_dout4_next;W_dout4 = W_dout4_next;
    I_dout5 = I_dout5_next;W_dout5 = W_dout5_next;
    I_dout6 = I_dout6_next;W_dout6 = W_dout6_next;
    I_dout7 = I_dout7_next;W_dout7 = W_dout7_next;
    I_dout8 = I_dout8_next;W_dout8 = W_dout8_next;
	
	global_addr_next = global_addr;
	global_start_next = global_start;
	   
	O_wren_next = 0;
	
	//determind the inputs    
    case(cur_addr1)//synopsys full_case
    0:begin I_dout1 = I_dout;W_dout1 = W_dout;end
    1:begin I_dout2 = I_dout;W_dout2 = W_dout;end
    2:begin I_dout3 = I_dout;W_dout3 = W_dout;end
    3:begin I_dout4 = I_dout;W_dout4 = W_dout;end
    4:begin I_dout5 = I_dout;W_dout5 = W_dout;end
    5:begin I_dout6 = I_dout;W_dout6 = W_dout;end
    6:begin I_dout7 = I_dout;W_dout7 = W_dout;end
    7:begin I_dout8 = I_dout;W_dout8 = W_dout;global_start_next=1;end
    endcase
    
	for (j = 0; j < K*K*sys_kernel/4; j = j + 1)
		begin
			S_in[j] = 0;
			W_in[j] = 0;
			X_in[j] = 0;
		end
	
	//state machine
	case (state)//synopsys full_case
	//state 0: initial
		0: 
			if (start_conv)
				begin
					state_next = 1;
	
					W_addr_next = W_addr + 1;
					
					I_n_addr_next = I_n_addr;
					I_i_addr_next = I_i_addr + 2;
					I_i_key_next = I_i_key;
					I_j_addr_next = I_j_addr;
				end
					
	//state 1: convolution process: data flow
		1:
			begin
				if (cur_addr1 < K*K*sys_kernel/4)
					begin
						S_in[cur_addr1] = S_out[cur_addr1-1];
						case(cur_addr1)//synopsys full_case
                            0:begin X_in[cur_addr1] = I_dout1[7:0];  W_in[cur_addr1] = W_dout1[7:0];end
                            1:begin X_in[cur_addr1] = I_dout1[15:8]; W_in[cur_addr1] = W_dout1[15:8];end
                            2:begin X_in[cur_addr1] = I_dout1[23:16];W_in[cur_addr1] = W_dout1[23:16];end
                            3:begin X_in[cur_addr1] = I_dout1[31:24];W_in[cur_addr1] = W_dout1[31:24];end
                            4:begin X_in[cur_addr1] = I_dout1[39:32];W_in[cur_addr1] = W_dout1[39:32];end
                            5:begin X_in[cur_addr1] = I_dout1[47:40];W_in[cur_addr1] = W_dout1[47:40];end
                            6:begin X_in[cur_addr1] = I_dout1[55:48];W_in[cur_addr1] = W_dout1[55:48];end
                            7:begin X_in[cur_addr1] = I_dout1[63:56];W_in[cur_addr1] = W_dout1[63:56];end
                        endcase
					end
					
				if (cur_addr2 < K*K*sys_kernel/4+1)
					begin
						S_in[cur_addr2-1] = S_out[cur_addr2-2];
						case(cur_addr2)//synopsys full_case
                            1:begin X_in[cur_addr2-1] = I_dout2[7:0];  W_in[cur_addr2-1] = W_dout2[7:0];end
                            2:begin X_in[cur_addr2-1] = I_dout2[15:8]; W_in[cur_addr2-1] = W_dout2[15:8];end
                            3:begin X_in[cur_addr2-1] = I_dout2[23:16];W_in[cur_addr2-1] = W_dout2[23:16];end
                            4:begin X_in[cur_addr2-1] = I_dout2[31:24];W_in[cur_addr2-1] = W_dout2[31:24];end
                            5:begin X_in[cur_addr2-1] = I_dout2[39:32];W_in[cur_addr2-1] = W_dout2[39:32];end
                            6:begin X_in[cur_addr2-1] = I_dout2[47:40];W_in[cur_addr2-1] = W_dout2[47:40];end
                            7:begin X_in[cur_addr2-1] = I_dout2[55:48];W_in[cur_addr2-1] = W_dout2[55:48];end
                            8:begin X_in[cur_addr2-1] = I_dout2[63:56];W_in[cur_addr2-1] = W_dout2[63:56];end
                        endcase
					end

				if (cur_addr3 < K*K*sys_kernel/4+2)
					begin
						S_in[cur_addr3-2] = S_out[cur_addr3-3];
						case(cur_addr3)//synopsys full_case
                            2:begin X_in[cur_addr3-2] = I_dout3[7:0];  W_in[cur_addr3-2] = W_dout3[7:0];end
                            3:begin X_in[cur_addr3-2] = I_dout3[15:8]; W_in[cur_addr3-2] = W_dout3[15:8];end
                            4:begin X_in[cur_addr3-2] = I_dout3[23:16];W_in[cur_addr3-2] = W_dout3[23:16];end
                            5:begin X_in[cur_addr3-2] = I_dout3[31:24];W_in[cur_addr3-2] = W_dout3[31:24];end
                            6:begin X_in[cur_addr3-2] = I_dout3[39:32];W_in[cur_addr3-2] = W_dout3[39:32];end
                            7:begin X_in[cur_addr3-2] = I_dout3[47:40];W_in[cur_addr3-2] = W_dout3[47:40];end
                            8:begin X_in[cur_addr3-2] = I_dout3[55:48];W_in[cur_addr3-2] = W_dout3[55:48];end
                            9:begin X_in[cur_addr3-2] = I_dout3[63:56];W_in[cur_addr3-2] = W_dout3[63:56];end
                        endcase
					end
					
				if (cur_addr4 < K*K*sys_kernel/4+3)
					begin
						S_in[cur_addr4-3] = S_out[cur_addr4-4];
						case(cur_addr4)//synopsys full_case
                            3 :begin X_in[cur_addr4-3] = I_dout4[7:0];  W_in[cur_addr4-3] = W_dout4[7:0];end
                            4 :begin X_in[cur_addr4-3] = I_dout4[15:8]; W_in[cur_addr4-3] = W_dout4[15:8];end
                            5 :begin X_in[cur_addr4-3] = I_dout4[23:16];W_in[cur_addr4-3] = W_dout4[23:16];end
                            6 :begin X_in[cur_addr4-3] = I_dout4[31:24];W_in[cur_addr4-3] = W_dout4[31:24];end
                            7 :begin X_in[cur_addr4-3] = I_dout4[39:32];W_in[cur_addr4-3] = W_dout4[39:32];end
                            8 :begin X_in[cur_addr4-3] = I_dout4[47:40];W_in[cur_addr4-3] = W_dout4[47:40];end
                            9 :begin X_in[cur_addr4-3] = I_dout4[55:48];W_in[cur_addr4-3] = W_dout4[55:48];end
                            10:begin X_in[cur_addr4-3] = I_dout4[63:56];W_in[cur_addr4-3] = W_dout4[63:56];end
                        endcase
					end
					
				if (cur_addr5 < K*K*sys_kernel/4+4)
					begin
						S_in[cur_addr5-4] = S_out[cur_addr5-5];
						case(cur_addr5)//synopsys full_case
                            4 :begin X_in[cur_addr5-4] = I_dout5[7:0];  W_in[cur_addr5-4] = W_dout5[7:0];end
                            5 :begin X_in[cur_addr5-4] = I_dout5[15:8]; W_in[cur_addr5-4] = W_dout5[15:8];end
                            6 :begin X_in[cur_addr5-4] = I_dout5[23:16];W_in[cur_addr5-4] = W_dout5[23:16];end
                            7 :begin X_in[cur_addr5-4] = I_dout5[31:24];W_in[cur_addr5-4] = W_dout5[31:24];end
                            8 :begin X_in[cur_addr5-4] = I_dout5[39:32];W_in[cur_addr5-4] = W_dout5[39:32];end
                            9 :begin X_in[cur_addr5-4] = I_dout5[47:40];W_in[cur_addr5-4] = W_dout5[47:40];end
                            10:begin X_in[cur_addr5-4] = I_dout5[55:48];W_in[cur_addr5-4] = W_dout5[55:48];end
                            11:begin X_in[cur_addr5-4] = I_dout5[63:56];W_in[cur_addr5-4] = W_dout5[63:56];end
                        endcase                    
					end
					
				if (cur_addr6 < K*K*sys_kernel/4+5)
					begin
						S_in[cur_addr6-5] = S_out[cur_addr6-6];
						case(cur_addr6)//synopsys full_case
                            5 :begin X_in[cur_addr6-5] = I_dout6[7:0];  W_in[cur_addr6-5] = W_dout6[7:0];end
                            6 :begin X_in[cur_addr6-5] = I_dout6[15:8]; W_in[cur_addr6-5] = W_dout6[15:8];end
                            7 :begin X_in[cur_addr6-5] = I_dout6[23:16];W_in[cur_addr6-5] = W_dout6[23:16];end
                            8 :begin X_in[cur_addr6-5] = I_dout6[31:24];W_in[cur_addr6-5] = W_dout6[31:24];end
                            9 :begin X_in[cur_addr6-5] = I_dout6[39:32];W_in[cur_addr6-5] = W_dout6[39:32];end
                            10:begin X_in[cur_addr6-5] = I_dout6[47:40];W_in[cur_addr6-5] = W_dout6[47:40];end
                            11:begin X_in[cur_addr6-5] = I_dout6[55:48];W_in[cur_addr6-5] = W_dout6[55:48];end
                            12:begin X_in[cur_addr6-5] = I_dout6[63:56];W_in[cur_addr6-5] = W_dout6[63:56];end
                        endcase
					end
					
				if (cur_addr7 < K*K*sys_kernel/4+6)
					begin
						S_in[cur_addr7-6] = S_out[cur_addr7-7];
						case(cur_addr7)//synopsys full_case
                            6 :begin X_in[cur_addr7-6] = I_dout7[7:0];  W_in[cur_addr7-6] = W_dout7[7:0];end
                            7 :begin X_in[cur_addr7-6] = I_dout7[15:8]; W_in[cur_addr7-6] = W_dout7[15:8];end
                            8 :begin X_in[cur_addr7-6] = I_dout7[23:16];W_in[cur_addr7-6] = W_dout7[23:16];end
                            9 :begin X_in[cur_addr7-6] = I_dout7[31:24];W_in[cur_addr7-6] = W_dout7[31:24];end
                            10:begin X_in[cur_addr7-6] = I_dout7[39:32];W_in[cur_addr7-6] = W_dout7[39:32];end
                            11:begin X_in[cur_addr7-6] = I_dout7[47:40];W_in[cur_addr7-6] = W_dout7[47:40];end
                            12:begin X_in[cur_addr7-6] = I_dout7[55:48];W_in[cur_addr7-6] = W_dout7[55:48];end
                            13:begin X_in[cur_addr7-6] = I_dout7[63:56];W_in[cur_addr7-6] = W_dout7[63:56];end
                        endcase
					end
					
				if (cur_addr8 < K*K*sys_kernel/4+7)
					begin
						S_in[cur_addr8-7] = S_out[cur_addr8-8];
						case(cur_addr8)//synopsys full_case
                            7 :begin X_in[cur_addr8-7] = I_dout8[7:0];  W_in[cur_addr8-7] = W_dout8[7:0];end
                            8 :begin X_in[cur_addr8-7] = I_dout8[15:8]; W_in[cur_addr8-7] = W_dout8[15:8];end
                            9 :begin X_in[cur_addr8-7] = I_dout8[23:16];W_in[cur_addr8-7] = W_dout8[23:16];end
                            10:begin X_in[cur_addr8-7] = I_dout8[31:24];W_in[cur_addr8-7] = W_dout8[31:24];end
                            11:begin X_in[cur_addr8-7] = I_dout8[39:32];W_in[cur_addr8-7] = W_dout8[39:32];end
                            12:begin X_in[cur_addr8-7] = I_dout8[47:40];W_in[cur_addr8-7] = W_dout8[47:40];end
                            13:begin X_in[cur_addr8-7] = I_dout8[55:48];W_in[cur_addr8-7] = W_dout8[55:48];end
                            14:begin X_in[cur_addr8-7] = I_dout8[63:56];W_in[cur_addr8-7] = W_dout8[63:56];end
                        endcase
					end
				
				//caculate the Input Address
				W_addr_next = W_addr + 1;
				
				if (I_i_addr == I_i_key+2)
				    begin
                        I_i_addr_next = I_i_key;
                    
                        if (I_n_addr == N-1)
                            begin
                                I_n_addr_next = 0;
                                
                                if (I_j_addr_next == C-4)
                                   begin
                                       I_j_addr_next = 0;
                                       
                                       if (I_i_key == C-4)
                                           begin
                                               I_i_key_next = 0;
                                               I_i_addr_next = 0;
                                           end
                                       else
                                           begin
                                               I_i_key_next = I_i_key + 1;
                                               I_i_addr_next = I_i_addr - 1;
                                           end
					               end
					            else
                                   I_j_addr_next = I_j_addr + 1;
                            end
                        else
                            I_n_addr_next = I_n_addr + 1;
                    end
                else
                    I_i_addr_next = I_i_addr + 2;
				
				//record the current address for one sub cycle
				if (cur_addr1 == 0)
				    begin
                        S_in[0] = 0;
                        W_in[0] = W_dout1[7:0];
                        X_in[0] = I_dout1[7:0];
                    end
				if (cur_addr1 == K*K*sys_kernel/4-1)
                    cur_addr1_next = 0;
                else
                    cur_addr1_next = cur_addr1 + 1;
                //--------------------------
                if (cur_addr2 == 1)
                    begin
                        S_in[0] = 0;
                        W_in[0] = W_dout2[7:0];
                        X_in[0] = I_dout2[7:0];
                        
                        cur_addr2_next = cur_addr2 + 1;
                    end
                if (cur_addr2 == K*K*sys_kernel/4)   
                    cur_addr2_next = 1;
                else
                    cur_addr2_next = cur_addr2 + 1;
                //--------------------------
                if (cur_addr3 == 2)
                    begin
                        S_in[0] = 0;
                        W_in[0] = W_dout3[7:0];
                        X_in[0] = I_dout3[7:0];
                        
                        cur_addr3_next = cur_addr3 + 1;
                    end
                if (cur_addr3 == K*K*sys_kernel/4+1)
                    cur_addr3_next = 2;
                else
                    cur_addr3_next = cur_addr3 + 1;
                //--------------------------
                if (cur_addr4 == 3)
                    begin
                        S_in[0] = 0;
                        W_in[0] = W_dout4[7:0];
                        X_in[0] = I_dout4[7:0];
                        
                        cur_addr4_next = cur_addr4 + 1;
                    end
                if (cur_addr4 == K*K*sys_kernel/4+2)
                    cur_addr4_next = 3;
                else
                    cur_addr4_next = cur_addr4 + 1;
                //--------------------------
                if (cur_addr5 == 4)
                    begin
                        S_in[0] = 0;
                        W_in[0] = W_dout5[7:0];
                        X_in[0] = I_dout5[7:0];
                        
                        cur_addr5_next = cur_addr5 + 1;
                    end
                if (cur_addr5 == K*K*sys_kernel/4+3)
                    cur_addr5_next = 4;
                else
                    cur_addr5_next = cur_addr5 + 1;
                //--------------------------
                if (cur_addr6 == 5)
                    begin
                        S_in[0] = 0;
                        W_in[0] = W_dout6[7:0];
                        X_in[0] = I_dout6[7:0];
                        
                        cur_addr6_next = cur_addr6 + 1;
                    end
                if (cur_addr6 == K*K*sys_kernel/4+4)
                    cur_addr6_next = 5;
                else
                    cur_addr6_next = cur_addr6 + 1;
                //--------------------------
                if (cur_addr7 == 6)
                    begin
                        S_in[0] = 0;
                        W_in[0] = W_dout7[7:0];
                        X_in[0] = I_dout7[7:0];
                        
                        cur_addr7_next = cur_addr7 + 1;
                    end
                if (cur_addr7 == K*K*sys_kernel/4+5)
                    cur_addr7_next = 6;
                else
                    cur_addr7_next = cur_addr7 + 1;
                //--------------------------
                if (cur_addr8 == 7)
                    begin
                        S_in[0] = 0;
                        W_in[0] = W_dout8[7:0];
                        X_in[0] = I_dout8[7:0];
                        
                        cur_addr8_next = cur_addr8 + 1;
                    end
                if (cur_addr8 == K*K*sys_kernel/4+6)
                    cur_addr8_next = 7;
                else
                    cur_addr8_next = cur_addr8 + 1;
                
                //record the address for the whole convolution cycle
                if (global_addr == 0 && global_start)
                    begin
                        W_addr_next = W_addr + 1;
                        
                        if (I_n_addr == N-1) I_n_addr_next = 0;
                        else I_n_addr_next = I_n_addr + 1;
                        
                        if (I_i_addr == I_i_key+2) I_i_addr_next = I_i_key;
                        else I_i_addr_next = I_i_addr + 2;
                        
                        I_j_addr_next = I_j_addr;
                        
                        cur_addr1_next = cur_addr1 + 1;
                        
                        if (global_start)
                            global_addr_next = global_addr + 1;
                        else
                        if (global_start == 1 && cur_addr1 == 0)
                            global_addr_next = global_addr;
                    end
                    
			    if (global_start)
                    begin
                        if (global_addr == K*K*N/8-1)
                            begin
                                global_addr_next = 0;
                                O_wren_next = 1;
                            end
                        else
                            global_addr_next = global_addr + 1;
                        
                        if (global_addr == K*K*N/8-8-1)
                            begin
                                if(counter == Rprime*Cprime-1)
                                    W_key_next = W_addr;
                            end
                        else
                        if (global_addr == K*K*N/8-8-2)
                            begin
                                if(counter != Rprime*Cprime-1)
                                    W_addr_next = W_key;
                            end
					end
					
				//the condition to finish
				if (O_ram_addr == Rprime*Cprime*M)
					state_next = 2;
			end
			
	//state 2: process over
		2:
			begin
				end_conv = 1;
			end
		endcase
end

endmodule

///////////////////////////////////////
module PE(
	input clk,
	
	input signed [24:0] S_in,
	input signed [7:0] W_in,
	input signed [7:0] X_in,
	
	output reg signed [24:0] S_out
);

wire signed [24:0] temp = X_in * W_in;

always @(posedge clk)
begin
	S_out <= temp + S_in;
end

endmodule

///////////////////////////////////////
module RELU(
    input [24:0] din_relu,
    output [24:0] dout_relu
);

assign dout_relu = (din_relu[24] == 0)? din_relu : 0;

endmodule