# Device Trees, Device Tree Overlays & Kernel Modules

## Device Trees

In the linux world, particularly on ARM based embedded systems, a Device Tree is like a map that tells the kernel what hardware exists on a board. On an x86 PC the BIOS or Unified Extensible Firmware Interface (UEFI) will supply hardware information to the OS. On an linux ARM system it is the job of the Device Tree.

A Device Tree provides hardware details like like GPIO pins, I2C, SPI, UART and, crucially, register addresses for each piece of hardware. In ARM land each device has a magic physical memory address and when an app or kernel module writes data to that address it is actually sending data to that device. It can be an actual physical device, such as a network card, or a destination inside the FPGA fabric of the programmable logic on our Kria boards.

## Device Tree Overlays

To implement our Kria applications we need to add to the device tree _after_ the Kria board boots up since the P/L FPGA fabric won't be programmed with the bitfile until after the initial boot.

A Kria application will consist of three components:

1. A .bin file. This is the actual firmware bit file which implements our design as Lookup Tables and registers within the FPGA fabric.
2. A .dtbo file. A Device Tree Blob Overlay that tells the kernel how much memory to reserve for the DMA, the addresses of the registers for DMA Controller or GPIO devices, clock configuration, etc.
3. A shell.json file containing metadata that enables dfx-mgr to manage hardware acceleration.

The .dtbo file is the device tree overlay. It's purpose is to "patch" the existing device tree at boot so that the kernel will see our firmware like any other device.

## Device Tree Structure Include

The create an overlay we first need to start with a Device Tree Structure Include (\*.dtsi) file. This is a text file which describes the hardware we want to add to the Device tree after boot. To build this project we initially export out firmware design from Vivado to a hardware handoff file (.xsa). We than use this to construct a pl.dtsi file (see the [README.md](./firmware/README.md) file for more details).

When the pl.dtsi file is created there initially three parts to it.

### 1. Header

The first part is the header

```
/dts-v1/;
/plugin/;
```

The first line indicates that the file is using Device Tree Syntax, Version 1. The second line indicates that you are defining a Linux Device Tree _Overlay_ that will be added to the existing device tree and _not_ a stand alone device tree i.e it will be plugged into the existing device tree.

### 2. FPGA

The next section describes the FPGA itself.

```
&fpga_full {
	firmware-name = "hygrometer.bit.bin";
	resets = <&zynqmp_reset 116>;
	clocking0: clocking0 {
		#clock-cells = <0>;
		assigned-clock-rates = <99999001>;
		assigned-clocks = <&zynqmp_clk 71>;
		clock-output-names = "fabric_clk";
		clocks = <&zynqmp_clk 71>;
		compatible = "xlnx,fclk";
	};
	clocking1: clocking1 {
		#clock-cells = <0>;
		assigned-clock-rates = <99999001>;
		assigned-clocks = <&zynqmp_clk 72>;
		clock-output-names = "fabric_clk";
		clocks = <&zynqmp_clk 72>;
		compatible = "xlnx,fclk";
	};
	afi0: afi0 {
		compatible = "xlnx,afi-fpga";
		config-afi = < 0 0>, <1 0>, <2 0>, <3 0>, <4 0>, <5 0>, <6 0>, <7 0>, <8 0>, <9 0>, <10 0>, <11 0>, <12 0>, <13 0>, <14 0xa00>, <15 0x000>;
		resets = <&zynqmp_reset 116>, <&zynqmp_reset 117>, <&zynqmp_reset 118>, <&zynqmp_reset 119>;
	};
};
```

The &fpga_full section give the OS information about the FPGA's bitfile, it's clocking information (clocking0, clocking1), and it's AXI FIFO Interface (AFI) registers (afi0). These are parsed and applied by the afi driver before the bit stream is loaded. These registers manage the data that flows though the high-performance (HP) or general-purpose AXI ports between the ARM processing system and the FPGA fabric.

### 3. DMA

The next section is an &amba section for the DMA controller. &amba refers to the [Advanced Microcontroller Bus Architecture](https://support.arm.com/architectures/amba), an open standard specification developed by ARM to manage functional blocks within a System On Chip (SOC). The [Advanced eXtensible Interface (AXI)](https://support.arm.com/documentation/ihi0022/latest/) point to point communication protocol is a part of this architecture. A .dtsi file can potentially have more than one &amba sections, one for each bus node. In fact we will need to add one manually after the file generation to use dma proxy instead of direct dma.

```
&amba {
	#address-cells = <2>;
	#size-cells = <2>;
	axi_dma: dma@a0000000 {
		#dma-cells = <1>;
		clock-names = "m_axi_mm2s_aclk", "m_axi_s2mm_aclk", "s_axi_lite_aclk";
		clocks = <&zynqmp_clk 71>, <&zynqmp_clk 71>, <&zynqmp_clk 71>;
		compatible = "xlnx,axi-dma-7.1", "xlnx,axi-dma-1.00.a";
		interrupt-names = "mm2s_introut", "s2mm_introut";
		interrupt-parent = <&gic>;
		interrupts = <0 89 4 0 90 4>;
		reg = <0x0 0xa0000000 0x0 0x10000>;
		xlnx,addrwidth = <0x40>;
		xlnx,sg-length-width = <0x1a>;
		dma-channel@a0000000 {
			compatible = "xlnx,axi-dma-mm2s-channel";
			dma-channels = <0x1>;
			interrupts = <0 89 4>;
			xlnx,datawidth = <0x20>;
			xlnx,device-id = <0x0>;
		};
		dma-channel@a0000030 {
			compatible = "xlnx,axi-dma-s2mm-channel";
			dma-channels = <0x1>;
			interrupts = <0 90 4>;
			xlnx,datawidth = <0x20>;
			xlnx,device-id = <0x0>;
		};
	};
};

```

The most important thing to note here is the dma-channel sections. There are two. dma-channel@a0000000 is the memory map to stream control for data going from DDR to the P/L via DMA. dma-channel@a0000030 is the control for data going from PL back to DDR via DMA.

The outgoing DMA channel is controlled by writing the correct sequence of bits to register at address a0000000. The incoming DMA channel is controlled by writing the correct sequence of bits to register at address a0000030.

a0000000 is the starting address of the S_AXI_LITE interface from the Address Editor in Vivado.

## DMA Proxy

In order to make writing the user space application easier we will use DMA Proxy instead of Direct DMA. The reason for this is that it we can map kernel allocated buffers into user space (using mmap) and move the data in and out with ioctl calls. However to do this we need to add to the generated dtsi file.

First we need to add a section for reserving the memory for the proxy buffers. When using mmap memory will be allocated from this reserved, contiguous buffer.

```
&{/} {
    reserved_memory {
        #address-cells = <2>;
        #size-cells = <2>;
        ranges;

        dma_proxy_reserved: buffer {
            compatible = "shared-dma-pool";
            size = <0x0 0x4000000>; /* 64MB */
            alignment = <0x0 0x00001000>; /* 4KB alignment */
            reusable;
        };
    };
};
```

But how does mmap know to use this memory instead of some other section of the system memory? It knows, because it will be called with a file descriptor opened against a character device in the /dev directory. Which character device? That is the purpose of the second &amba section that we will add to the file to create a new bus node.

```
&amba {
    dma_proxy {
        compatible = "xlnx,dma_proxy";
        dmas = <&axi_dma 0  &axi_dma 1>;
        dma-names = "dma_proxy_tx", "dma_proxy_rx";
    };
};
```

This final section of the file connects the two axi dam channels, &axi_dma 0 & 1, to the two character devices - **/dev/dma_proxy_tx**(for writing) and **/dev/dma_proxy_rx** (for reading) used from moving data in out out of the P/L via DMA.

Once the file is complete we compile it on the kria using dtc. Again see the [README.md](./firmware/README.md) file for more details.

## Kernel Module

Adding the device with a .dtbo file however isn't quite enough. A Device tree Overlay will supply a hardware description - clock config, registers, addresses - but in order to be accessible user space applications it still needs a matching platform driver that can find to it's device nodes, bind to them correctly and initialize hardware. In other words, it needs a matching kernel module (.ko).

The **/dev/dma_proxy_tx** and **/dev/dma_proxy_rx** character devices will not appear in the /dev directory until this kernel module is loaded.

Lucky for us Xilinx supplies an open source Proxy DMA driver at https://github.com/Xilinx-Wiki-Projects/software-prototypes.git - all we have to do is create a makefile for it. You can find a fork of this in the [xilinx](./xilinx) folder.
