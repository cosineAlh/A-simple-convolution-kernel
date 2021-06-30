all: comp sim clean

comp:
	vcs -full64 -v2005 -debug_access+all CNN_tb.v CNN.v

sim:
	./simv

clean:
	rm -rf csrc DVEfiles *.vpd simv simv* ucli.key
