# CSE x25 Lab 1
TOP_MODULE = separator_3x3
SYNTH_SOURCES += $(TOP_MODULE).sv
SYNTH_SOURCES += ../provided_modules/dff.sv
SYNTH_SOURCES += ../provided_modules/inv.sv
SYNTH_SOURCES += ../Memory/ram_1r1w_sync.sv
NONSYNTH_SOURCES += ../provided_modules/nonsynth_clock_gen.sv
NONSYNTH_SOURCES += ../provided_modules/nonsynth_reset_gen.sv
-include ../simulation.mk
-include ../fpga.mk
