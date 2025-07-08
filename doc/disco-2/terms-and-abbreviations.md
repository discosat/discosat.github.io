# Terms and Abbreviations

## Software, firmware & tools
| Term | Meaning |
| ---- | ---------- |
| **PicoCoreMX8MP** | The System-on-Module (SoM) used in the DISCO II project. It contains the NXP i.MX 8M Plus processor. |
| **Cortex-M7** | The [low-power core](https://github.com/discosat/disco-ii-cortex-m7-scheduler) in the PicoCoreMX8MP. It is responsible for low-power operations and contains a [`csp_proc` server](https://github.com/discosat/csp_proc) for flight planning. |
| **Cortex-A53** | The high-power cores in the PicoCoreMX8MP. They responsible for running the Linux operating system and applications for image acquisition and processing. |
| **CSP** | [CubeSat Space Protocol](https://github.com/spaceinventor/libcsp/): The network library used in the DISCO II project. It is a custom protocol used for communication between the modules of the satellite, as well as the ground station. |
| **libparam** | [A library](https://github.com/spaceinventor/libparam/) used in the DISCO II project for managing parameters on CSP nodes. Each CSP node has a list of parameters that can be retrieved/set remotely and used to trigger callbacks. |
| **CSH** | The CSP Shell. A command-line interface for interacting with CSP nodes. It can be used to set parameters, configure DIPP pipelines, program `csp_proc` procedures etc. via the command-line. |
| **csp_proc** | [The library](https://discosat.github.io/csp_proc/) used in the DISCO II project for flight planning. It can be used to dynamically create procedures that can be executed on the Cortex-M7 core when it is not in contact with the ground station. |
| **app-sys-manager** | An application that exposes the Linux-side of the PicoCoreMX8MP over CSP. It provides a remote interface to run system calls on the Linux system. |
| **Yocto** | A tool used to create custom Linux distributions for embedded systems. It is used in the DISCO II project to [build the system image](https://github.com/discosat/disco-ii-picocore-mx8mp-yocto) for the PicoCoreMX8MP. |
| **U-Boot** | The main bootloader on the PicoCoreMX8MP. It is used to load the Linux kernel, device tree, etc. and boot the Cortex-M7 core. |
| **DIPP** | The DISCO II Image Processing Pipeline. It is responsible for processing the images captured by the camera controller. |
