# Sobel Filter FPGA Project by Fabert C.

## Repository Structure
The repository has the following file structure:

```bash
| README.md (This File)
├── 
│   ├── provided_modules
│   │   └── *.sv # pre-written SystemVerilog files such add the icebreaker.pcf for changing icebreaker │   │            # pmods layout
│   │
│   ├── Display
│   │   ├── Makefile # Used for building Display test
│   │   ├── clock_display.sv # Module that initializes the clock for the display
│   │   ├── display_480p.sv  # Module that initializes the display components such as hsync, vsync, etc
│   │   └── testbench.sv     # Tests whether the display_480p.sv produces the correct hsync, vsync, etc
│   │ 		└── Makefile     # used to create the iverilog.vcd and verilator.fst files that show gtkwave
│   │
│   ├── Matlab_image_to_hex
│   │   ├── color_image.jpeg # Image example for the sobel filter
│   │   ├── hex_to_image.m   # Converts hex values into an image
│   │   └── image_to_hex.m   # Convert a jpeg image to gray scale then to hex values and stores them in a │   │					       # .txt file
│   │
│   ├── Memory
│   │   ├── ram_1r1w_sync.sv  # 1 port read 1 port write synchronous memory module
│   │   └── sync_valid_mem.sv # ram_1r1w_sync.sv but with a valid_o output that tells next read memory is │   │							# valid after a read address
│   │
│   ├── separator_3x3
│   │   ├── data.hex         # .hex files with a predefined 4x4 matrix for testing separator module
│   │   ├── separator_3x3.sv # Separates array of data into a 3x3 matrix
│   │   └── testbench.sv     # Tests if the separator_3x3 produces correct result
│   │ 		└── Makefile     # used to create the iverilog.vcd and verilator.fst files that show gtkwave
│   │
│   ├── sobel_core
│   │   ├── input_image   # Holds the hex values of the image that will be processed
│   │   ├── output_image  # Holds the process image hex values.  Only testbench produces file here.
│   │   ├── soble_core.sv # Convolves 3x3 data with 2 kernels from separator_3x3 and outputs 4-bit data
│   │   ├── testbench.sv     # Tests if the separator_3x3 produces correct result
│   │ 		└── Makefile     # Used to create the iverilog.vcd and verilator.fst files that show gtkwave
│   │   └── top.sv           # Programs the icebreaker board with all the modules combined
│   │
│   ├── fpga.mk # Make file for programming the icebreaker board
│   ├── simulation.mk # Make file for testbench simulation
└──
```
Each makefile provides a `make help` command that describes the
available commands.

## Programming The Icebreaker Board
To be able to program the icebreaker board to display a sobel image, you must be in the sobel_core folder and run the command `make prog`.  This will also create a .nplog file that will show you how many LUTs your board uses, your max clk frequency, and other info.  In addition, if you want to change the scaling of the image shown, there is a parameter named scale_lp in top.sv which you can change: the default scaling is x4 but can be change as low as x1.

## Changing Image To Apply Sobel Filter
To change the image you want to apply the sobel filter to, you must insert the .jpeg image into the Matlab_image_to_hex folder, rename it to color_image.jpeg, and run the Matlab_image_to_hex/image_to_hex.m file on matlab.  Doing this will create a file named gray_image.txt in the sobel_core/input_image.  NOTE: inorder for the image to properly display on the Icebreaker board, the image must be rescaled to have a width: 160 and height: 120: this is the default. Then you can do the steps in the Programming The Icebreaker Board section.

## Displaying The Converted Image On Matlab
After converting an image to it's hex values in Matlab, you can generated a file named image_out.txt, which is the hex values of the image with the sobel filter applied, in sobel_core/image_out.  To do this, you must be in the sobel_core folder and run the command 'make test_verilator' which will run testbench.sv. In the testbench, there are image height and image width parameters that must match the height and width used in Matlab_image_to_hex/image_to_hex.m. After the simulation is done, you must open Matlab and run Matlab_image_to_hex/hex_to_image.m.  This will display a visual representation of the image_out.txt file.  NOTE: You must use the same width and height as the original image.

## Hardware Required
iCEBreaker FPGA: [link to buy](https://1bitsquared.com/products/icebreaker)

PMOD Digital Video Interface: [link to buy](https://1bitsquared.com/products/pmod-digital-video-interface?variant=11770730020911&currency=USD&utm_medium=product_sync&utm_source=google&utm_content=sag_organic&utm_campaign=sag_organic&gclid=CjwKCAjw_MqgBhAGEiwAnYOAehxQyjnhFbSThXkY0NzWJkbUuMskxvQQC1vccm7IIo_w61NTHTmSuhoCrkUQAvD_BwE)

## Hardware Setup
The PMOD DVI must be connected to PMOD ports 1A and 1B.  An example can be seen [here](https://projectf.io/posts/fpga-graphics/).

## Other Repositories Used
For PMOD DVI: https://github.com/projf/projf-explore

## Tools
To be able to run this project you will need the following tools:

- *Icarus Verilog*: https://bleyer.org/icarus/ (v10.0)
- *Verilator*: https://verilator.org/guide/latest/index.html (v5.0)
- *GTKWave*: https://gtkwave.sourceforge.net/ (v3.0)
- *Yosys*: https://yosyshq.net/yosys/ (v0.23)
- *nextpnr-ice40*: https://github.com/YosysHQ/nextpnr (v0.4)
- *project-icestorm*: https://clifford.at/icestorm (No Version)

### Typical Installation - All Operating Systems
If you are running on Ubuntu, create `/etc/udev/rules.d/50-lattice-ftdi.rules` (you will need to use sudo), and paste the contents: 

    `ACTION=="add", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE:="666"`
    
Otherwise you will get the eqivalent of a 'device not found' error when running `iceprog`.


### Advanced Installation - Linux	
If you like doing things the hard way, you can use these
instructions. Please ensure that you have the correct versions (listed
above).

- On Ubuntu/Debian-like distributions, run: `sudo apt install iverilog verilator gtkwave yosys nextpnr-ice40 fpga-icestorm`

- Then, create `/etc/udev/rules.d/50-lattice-ftdi.rules` (you will need to use sudo), and paste the contents: 

    `ACTION=="add", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE:="666"`
    
- Double check your installed tool versions against the ones above.


### Advanced Installation - MacOS
- Install Homebrew: https://brew.sh/
- Run: `brew install icarus-verilog verilator gtkwave`
- Run: `brew tap ktemkin/oss-fpga`
- Run: `brew install --HEAD icestorm yosys nextpnr-ice40`

### Advanced Installation - Windows
Not currently available

