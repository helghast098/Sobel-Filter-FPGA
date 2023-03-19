# CSE x25 Lab 1
TOP_MODULE = sobel_core
SYNTH_SOURCES += $(TOP_MODULE).sv
SYNTH_SOURCES += ../separator_3x3/separator_3x3.sv
SYNTH_SOURCES += ../Memory/ram_1r1w_sync.sv
SYNTH_SOURCES += ../Memory/sync_valid_mem.sv
SYNTH_SOURCES += ../Display/clock_display.sv
SYNTH_SOURCES += ../Display/display_480p.sv
SYNTH_SOURCES += ../provided_modules/inv.sv
SYNTH_SOURCES += ../provided_modules/dff.sv
NONSYNTH_SOURCES += ../provided_modules/nonsynth_clock_gen.sv
NONSYNTH_SOURCES += ../provided_modules/nonsynth_reset_gen.sv
-include ../simulation.mk
-include ../fpga.mk
