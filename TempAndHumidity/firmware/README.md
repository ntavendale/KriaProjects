# Axi DMA Demo Project

## First Things First

The fpga project was created in Vivado 2024.2 and the .tcl script to reproduce it was also made with this version. In all the sample code below I will use this version. If you are using a later version, substitute your Vivado version number in where appropriate.

I use a C:\Development folder to keep all my projects in so I will write these instructions as if I cloned this repo into the C:\Development\KriaProjects folder. If you use a different folder, update the sample code below to match your directory structure.

All of the development was done on Windows except where anything had to be compiled on the Kria board itself (since it is an Arm system). It is possible to set up a cross compile project on WSL to build everything, but that is beyond the scope of this demo.

For the Kria I used the Ubuntu 22.04 LTS image available here: [Install Ubuntu On AMD](https://ubuntu.com/download/amd). If it doesn't come with them installed already, use apt to instal gcc, g++, and make along with freepascal.

I also tried it with Ubuntu Server 24.04 LTS and it works as long as the firmware is up to date - BootFW-01.02 or later.

## Recreate Vivado Project And Block Diagram

The fpga project was created in Vivado 2024.2 and the .tcl script to reproduce it was also made wit this version. To recreate to you will need to use Vivado's Tcl console.

**NOTE:** When describing the paths we use a forward slash, "/", as the path delimiter.

1. Open Vivado, but do not open any project.
2. In the Tcl console change to the appropriate directory:

```
   cd c:/Development/KriaProjects/KriaAxiDma/firmware
```

3. Now recreate the project:

```
   source kria_hygrometer.tcl
```

This will recreate the project, and the hdl wrapper, but you will still need to generate the output products for the block diagram.

Open the block design, axi_dma_bd, and find it in the Design Sources. It should be under the hdl wrapper. Right click and select Generate Output Products. For Synthesis Options choose global and click generate.

After that you should be able to create the bit stream and export the hardware to a .xsa file (File -> Export -> Export Hardware...). Remember to include the bit stream.

When I do it I export the .xsa file as

```
 C:\Development\KriaProjects\TempAndHumidity\firmware\kria_hygrometer\outputs\hygrometer.xsa
```

You may also need to locate the .bin file. If the bit stream creation was successful it wil be in the _axi_dma_demo\axi_dma_demo.runs\impl_1_ directory (or some folder with a similar name). The file name will be _axi_dma_bd_wrapper.bin_. Copy it to the output directory with the .xsa file and rename it to _axi_dma_demo.bin_.

## Create Firmware Overlay From .xsa and .bin Files

### Clone The xilinx Device Tree Repo

ON YOUR PC: Ensure device-tree-xlnx is installed on system and matches Vivado/Vitis version:

```
> git clone https://github.com/Xilinx/device-tree-xlnx
> cd device-tree-xlnx
> git checkout xlnx_rel_v2024.2
```

This should give you a c:\Development\device-tree-xlnx directory on your PC with the appropriate brach checked out.

### Use xsct To Create The initial pl.dtsi File.

Next you need to open the Vitis xsct console. By default Vitis is installed in C:\\Xilinx\\Vitis\[version\]

Open a command prompt (cmd.exe, not PowerShell). Before using the xsct you are going to have to set up a Vitis environment.

First go to your outputs directory with your .xsa file.

```
cd C:\Development\KriaProjects\TempAndHumidity\firmware\kria_hygrometer\outputs
```

Next run the batch file to setup your Vitis environment. You may get a file not found message. IO ignored it and everything worked just fine so you should be OK to ignore it to.

```
C:\Xilinx\Vitis\2024.2\Settings64.bat
```

Now you can run the build_outputs.tcl script in xsct. This will open a new command prompt window. When the script is finished you can press any key to close the command prompt window.

```
C:\Xilinx\Vitis\2024.2\bin\xsct build_outputs.tcl
```

There should now be a pl.dtsi device-tree file in the generate_target directory.

### Update The pl.dtsi to use DMA Proxy

You will need to update the pl.dtsi to do two things.

1. Reserve Memory Buffer For the Proxy Buffers
1. Add the dma proxy entry

Add this to the top of your file to reserve the memory.

```
/* Reserve memory for DMA Proxy Buffers */
&{/} {
    reserved_memory {
        #address-cells = <2>;
        #size-cells = <2>;
        ranges;

        dma_proxy_reserved: buffer {
            compatible = "shared-dma-pool";
            size = <0x0 0x20000000>; /* 512MB */
            alignment = <0x0 0x00001000>; /* 4KB alignment */
            reusable;
        };
    };
};
```

Modify the device tree file by adding a dma_proxy entry directly after the dma.

```
&amba {
    dma_proxy {
        compatible = "xlnx,dma_proxy";
        dmas = <&axi_dma 0  &axi_dma 1>;
        dma-names = "dma_proxy_tx", "dma_proxy_rx";
    };
};
```

You can see the complete pl.dtsi file at the end of this document.

## Move On to The KRIA

Log into the KRIA and create a /home/ubuntu/development/hygrometer

Now on your PC you will need to copy up your .dtsi and .bin files.

```
cd C:\Development\KriaKR260Projects\TempAndHumidity\firmware\kria_hygrometer\outputs
scp pl.dtsi ubuntu@192.168.9.37:/home/ubuntu/development/hygrometer/pl.dtsi
scp hygrometer.bin ubuntu@192.168.9.37:/home/ubuntu/development/hygrometer/hygrometer.bin

```

Now, on the KRIA, compile pl.dtsi to .dtbo using DTC

```
cd /home/ubuntu/development/hygrometer
dtc -@ -O dtb -o hygrometer.dtbo pl.dtsi
```

If successful you can remove the .dtsi file and create the shell.json

```
rm pl.dtsi
echo '{ "shell_type" : "XRT_FLAT", "num_slots": "1" }' > shell.json
```

Now copy the folder containing the .bin, .dtbo, and .json files to /lib/firmware/xilinx/

```
cd ..
sudo cp -r hygrometer/ /lib/firmware/xilinx/
```

Verify the firmware overlay is installed by listing apps. it will have the folder name

```
sudo xmutil listapps
```

You should see something like the out put below:

```
Accelerator          Accel_type                            Base           Base_type      #slots(PL+AIE)         Active_slot

hygrometer           XRT_FLAT                         hygrometer            XRT_FLAT               (0+0)                  -1,
```

Unload any overlay if you have one loaded, then load the new one

```
sudo xmutil unloadapp
sudo xmutil loadapp hygrometer
```

List the apps again using xmutil and you should now see axi_dma_demo in Active_slot 0.

## Set Default Firmware (Optional)

If you want to load your app on boot, update the following file.

```
/etc/dfx-mgrd/default_firmware
```

It contains a single entry for the default app. Change it to axi_dma_demo.

You will need to run nano as root.

```
sudo nano /etc/dfx-mgrd/default_firmware
```

## Create dma_proxy Kernel Module (Xilinx Provided Driver)

In the /home/ubuntu/development directory clone the Git repository and cd to the directory for the driver.

```
~$ git clone https://github.com/Xilinx-Wiki-Projects/software-prototypes.git
~$ cd software-prototypes/linux-user-space-dma/Software/Kernel
```

Now create a Makefile with nano. Make is fussy when it comes to spaces vs tabs so when you copy and paste the text below you may need to massage it a little.

```
INC = /home/ubuntu/development/software-prototypes/linux-user-space-dma/Software/Common/
EXTRA_CFLAGS += -I$(INC)

obj-m += dma-proxy.o
all:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

#### Optional:

You can change the code to do an internal test and trace logging.

To enable the internal test open dma-proxy.c and look for the line

```
static unsigned internal_test = 0;
```

Change it to

```
static unsigned internal_test = 1;
```

To enable the trace logging open dma-proxy.c and look for the line

```
static unsigned trace = 0;
```

Change it to

```
static unsigned trace = 1;
```

#### Make The Driver:

```
make
```

## Install The Kernal Module

There should now be dma-proxy.ko file in the directory. This is a kernal object that can be dynamically loaded into the kernal space.

If you have enabled trace logging you can inspect the output. To do this open a second, seperate ssh terminal to the KRIA and run the following:

```
sudo dmesg -w
```

All the trace log messages from the kernel module should now print on this terminal.

Now we can load the kernel object.

```
sudo insmod dma-proxy.ko
```

Once loaded, verify it is installed

```
lsmod | grep dma
```

You should see a dma_proxy in the list.

Now verify the devices are there.

```
ls -al /dev/dma*
```

Running this command should produce an output similar to this.

```
crw------- 1 root root 506, 1 Jul 18 18:33 /dev/dma_proxy_rx
crw------- 1 root root 506, 0 Jul 18 18:33 /dev/dma_proxy_tx
crw------- 1 root root 507, 0 Jul 18 17:49 /dev/dmaproxy
```

Note the presence of the dma_proxy_tx & dma_proxy_rx we defined earlier in our pl.dtsi file. Note also that these two character devices can only bae accessed by root so any application that uses them must run as root. To get around this we set the permissions on the devices like so.

```

sudo chmod 666 /dev/dma_proxy_rx
sudo chmod 666 /dev/dma_proxy_tx

```

Now any application that uses our dma devices can run with regular user permissions.

## Build And Run The Test Application

Navigate to the User directory.

```
cd /home/ubuntu/development/software-prototypes/linux-user-space-dma/Software/User
```

Create a Makefile using nano.

```
INC = /home/ubuntu/development/software-prototypes/linux-user-space-dma/Software/Common/
EXTRA_CFLAGS += -I$(INC)

obj-m += dma-proxy-test.o
all:
    cc -o dma-proxy-test dma-proxy-test.c -I /home/ubuntu/development/software-prototypes/linux-user-space-dma/Software/Common/ -O0 -g3
clean:
    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

Then use make to build the app

```
make
```

Now you should see an app file, dma-proxy-test, in your directory. The application takes three arguments. The first is the number of DMA transfers to perform, the second is the size (in KB) of each transfer, and finally the last indicates whether to verify the transfer by comparing the data read back to the data written.

Run the application like so

```
./dma-proxy-test 1 128 1
```

You should get an output that looks similar to this:

```
DMA proxy test
Verify = 1
TX#0: ffff941bf000
RX#0: ffff93dbe000
Time: 710 microseconds
Transfer size: 128 KB
Throughput: 184 MB / sec
DMA proxy test complete
```

TX#0 and RX#0 represent the starting addresses of the respective buffers.

# Note For PetaLinux/Yocto Users

This dma-proxy driver doesn't build on Linux Kernel 6.4.0 and above, so a fix must be applied to dma-proxy.c https://github.com/Xilinx-Wiki-Projects/software-prototypes/pull/12

Find the create_class() call around line 431 and add this version check:

```

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 4, 0)
local_class_p = class_create(DRIVER_NAME);
#else
local_class_p = class_create(THIS_MODULE, DRIVER_NAME);
#endif

```

The ubuntu image for the kr260 is kernel 5.15.0-1027-xilinx-zynqmp so you won't need to do this on ubuntu.

## The Complete pl.dtsi File

This is the pl.dtsi file, complete with alterations for proxy-dma, that I used for this demo. Note that axi_dma is the name I gave the AXI Direct memory Access IP block in my initial Vivado design.

```
/*
 * CAUTION: This file is automatically generated by Xilinx.
 * Version: XSCT 2024.2.1
 * Today is: Tue Sep  1 18:25:27 2026
 */


/dts-v1/;
/plugin/;
/* Reserve memory for DMA Proxy Buffers */
&{/} {
    reserved_memory {
        #address-cells = <2>;
        #size-cells = <2>;
        ranges;

        dma_proxy_reserved: buffer {
            compatible = "shared-dma-pool";
            size = <0x0 0x20000000>; /* 512MB */
            alignment = <0x0 0x00001000>; /* 4KB alignment */
            reusable;
        };
    };
};
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
&amba {
    dma_proxy {
        compatible = "xlnx,dma_proxy";
        dmas = <&axi_dma 0  &axi_dma 1>;
        dma-names = "dma_proxy_tx", "dma_proxy_rx";
    };
};


```
