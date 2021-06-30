all: comp sim clean

ALL_DEFINE = +define+NET_SIM
# netlist
LIB_FILE = -v IH55LP_HS_RVT.v

comp:
	vcs -full64 -v2005 ${ALL_DEFINE} ${LIB_FILE} CNN_tb.v CNN.v -debug_access+all

sim:
	./simv

clean:
	rm -rf csrc DVEfiles *.vpd simv simv* ucli.key
