# CSE x25
# If you have iverilog or verilator installed in a non-standard path,
# you can override these to specify the path to the executable.
IVERILOG ?= iverilog
VERILATOR ?= verilator

## DO NOT MODIFY ANYTHING BELOW THIS LINE

# We will always provide these six targets:

help: targets-intro-help targets-help vars-intro-help vars-help

targets-help: sim-help
vars-help: sim-vars-help

targets-intro-help:
	@echo "make <target-name>"

sim-help:
	@echo "  help: Print this message."
	@echo "  lint: Run the Verilator linter on all source files."
	@echo "  test_verilator: Run veriilator testbenches and generate the verilator simulation log file."
	@echo "  test_iverilog: Run iverilog testbenches and generate the iverilog simulation log file."
	@echo "  all: Run the lint target, and if it passes, run the test target."
	@echo "  clean: Remove all compiler outputs."
	@echo "  extraclean: Remove all generated files (runs clean)."

vars-intro-help:
	@echo ""
	@echo "  Optional Environment Variables:"

sim-vars-help:
	@echo "    IVERILOG: Override this variable to set the location of your Icarus Verilog executable."
	@echo "    VERILATOR: Override this variable to set the location of your Verilator executable."


# lint runs the Verilator linter on your code.
lint:
	$(VERILATOR) --lint-only -top $(TOP_MODULE) $(TOP_MODULE.sv) $(SYNTH_SOURCES) -I../../provided_modules -I  $(VSIM_OPTS) -Wall $(s)

# test runs the simulation logs that you will check into git
test_verilator: verilator.log

test_iverilog: iverilog.log

# all runs the lint target, and if it passes, the test target
all: lint test


# Verilator Commands:
VSIM_EXE := verilator-tb
VSIM_LOG := verilator.log
VSIM_OPTS = -sv --timing --trace-fst -timescale-override 1ns/1ps
VSIM_WAV := verilator.fst
obj_dir/$(VSIM_EXE): testbench.sv $(NONSYNTH_SOURCES) $(SYNTH_SOURCES)
	$(VERILATOR) -o $(VSIM_EXE) $(VSIM_OPTS) --binary --top-module testbench testbench.sv $(NONSYNTH_SOURCES) $(SYNTH_SOURCES) --coverage

$(VSIM_LOG): ./obj_dir/$(VSIM_EXE)
	./obj_dir/$(VSIM_EXE) | tee verilator.log

# Icarus Verilog (iverilog) Commands:
ISIM_EXE := iverilog-tb
ISIM_LOG := iverilog.log
ISIM_WAV := iverilog.vcd
$(ISIM_EXE): testbench.sv $(NONSYNTH_SOURCES) $(SYNTH_SOURCES)
	$(IVERILOG) -g2005-sv -o $(ISIM_EXE) testbench.sv $(NONSYNTH_SOURCES) $(SYNTH_SOURCES)

$(ISIM_LOG): $(ISIM_EXE)
	./$(ISIM_EXE) | tee iverilog.log
	echo "Current System Time is: $(shell date +%X--%x)" >> iverilog.log

# Remove all compiler outputs
clean:
	rm -f $(ISIM_EXE)
	rm -rf obj_dir

# Remove all generated files
extraclean: clean
	rm -f $(ISIM_LOG)
	rm -f $(VSIM_LOG)
	rm -f $(ISIM_WAV)
	rm -f $(VSIM_WAV)

.PHONY: $(ISIM_LOG) $(VSIM_LOG) help intro-targets-help targets-help sim-help intro-vars-help vars-help sim-vars-help lint test all clean extraclean
