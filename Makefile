# Paths
SRC_RTL = $(wildcard src/rtl/**/*.v)
SRC_SIM = $(wildcard src/sim/**/*.v)
BUILD_DIR = build
SIM_OUT = $(BUILD_DIR)/sim_out
VCD_FILE = $(BUILD_DIR)/dump.vcd

# Targets
all: sim

sim: $(SIM_OUT)
	vvp $(SIM_OUT)

$(SIM_OUT): $(SRC_RTL) $(SRC_SIM)
	mkdir -p $(BUILD_DIR)
	iverilog -o $(SIM_OUT) $(SRC_RTL) $(SRC_SIM)

gtkwave:
	gtkwave $(VCD_FILE)

clean:
	rm -rf $(BUILD_DIR)

