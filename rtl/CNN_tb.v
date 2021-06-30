`timescale 1ns / 1ns
module CNN_tb;

// Inputs
reg clk;
reg rst;
reg start_conv;

// Outputs
wire end_conv;

wire [31:0] I_addr;
wire [31:0] W_addr;
wire [31:0] O_addr;

reg [8*8-1:0] I_dout;
reg [8*8-1:0] W_dout;

wire [24:0] O_din;
wire O_wren;

reg [1:0] ci, co;

parameter N = 8;
parameter M = 8;
parameter R = 64;
parameter C = 64;
parameter S = 1;
parameter K = 4;
parameter Rprime = R*S-K+1;
parameter Cprime = C*S-K+1;

// Instantiate the Unit Under Test (UUT)
//CNN #(N,M,R,C,S,K,Rprime,Cprime) uut(
CNN uut(
    .clk(clk), 
    .rst(rst), 
    .start_conv(start_conv), 
    .end_conv(end_conv),
    .ci(ci),
    .co(co),
    .I_ram_addr(I_addr),
    .W_ram_addr(W_addr),
    .O_ram_addr(O_addr),
    .I_ram_dout(I_dout),
    .W_ram_dout(W_dout),
    .O_ram_din(O_din),
    .O_wren(O_wren)
);

//output file
integer fp_w;

//memories
reg [7:0] I_mem[0:N*R*C-1];
reg [7:0] W_mem[0:N*M*R*C-1];
reg [24:0] O_mem_expected[0:M*Rprime*Cprime-1];

//initialize the memories
initial
begin
    $readmemb("./ifm_bin.txt", I_mem);
    $readmemb("./weight_bin.txt", W_mem);
    $readmemb("./ofm_bin.txt", O_mem_expected);
    fp_w=$fopen("./my_output.txt","w");
end

reg error = 0;

//main data flow & compared the results with the answer
always @(posedge clk)
begin
    I_dout[7:0] <= I_mem[I_addr];
    I_dout[15:8] <= I_mem[I_addr+1];
    I_dout[23:16] <= I_mem[I_addr+2];
    I_dout[31:24] <= I_mem[I_addr+3];
    I_dout[39:32] <= I_mem[I_addr+64];
    I_dout[47:40] <= I_mem[I_addr+65];
    I_dout[55:48] <= I_mem[I_addr+66];
    I_dout[63:56] <= I_mem[I_addr+67];

    W_dout[7:0] <= W_mem[8*W_addr];
    W_dout[15:8] <= W_mem[8*W_addr+1];
    W_dout[23:16] <= W_mem[8*W_addr+2];
    W_dout[31:24] <= W_mem[8*W_addr+3];
    W_dout[39:32] <= W_mem[8*W_addr+4];
    W_dout[47:40] <= W_mem[8*W_addr+5];
    W_dout[55:48] <= W_mem[8*W_addr+6];
    W_dout[63:56] <= W_mem[8*W_addr+7];
    
    if (O_wren)
        begin
            if (O_din != O_mem_expected[O_addr])
                error <= 1;
                
            $fwrite(fp_w,"%d\n",O_din);        //write results into a file
            if(error)                          //if get the correct result, write "True",otherwise, write "False"
                $fwrite(fp_w,"False\n");
            else
                $fwrite(fp_w,"True\n");
            //$display("Outdata %x error = %x \n", O_din, error);
        end
end

initial begin
    clk = 0;
    rst = 1;
    ci = 2'b00;
    co = 2'b00;
    start_conv = 0;

    #5;
    rst = 0;
    #5;
    start_conv = 1;
    #10;
    start_conv = 0;
end

//clock generator
always #5 clk = ~clk;

//how to close the code
always @(posedge clk)
begin
    if(end_conv)
    begin
        # 10;
        $fclose(fp_w);
        $finish;
    end
end
    
endmodule