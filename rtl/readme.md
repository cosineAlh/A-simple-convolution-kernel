In this version, we test 32 channels and 32 kernel numbers(the original data which is given by TA).

The testbench will generate a txt file called "my_output.txt", it records all the outputs and compared with the answer read by testbench, if the answer is correct, we write "True" behind the output, e.g. 123456 True

If you want to change channel number, please change the parameter N, M and ic,oc signal in testbench.e.g. N=8 M=8 ic=2b'00 oc=2b'00