# Example application including `csp_proc`

This examples demonstrates a simple application connected to a network via `libcsp`, including `libparam` to expose parameters and `csp_proc` to run procedures on the network. After this, it should hopefully be clear how simple it is to integrate `csp_proc` after setting up a basic `libcsp` + `libparam` application.

For this example, we'll build for a POSIX system (converting to e.g. FreeRTOS is mostly just a matter of subsituting pthreads for FreeRTOS tasks). A `libcsp`-based application will usually consist of a few standard components like shown below. (Read the corresponding docs of [`libcsp`](https://libcsp.github.io/libcsp/) and [`libparam`](https://github.com/spaceinventor/libparam/blob/master/doc/introduction.rst) for more information)

```c
#include <pthread.h>
#include <stdint.h>

#include <csp/csp.h>
#include <param/param_server.h>
#include <vmem/vmem_server.h>

void * vmem_server_task(void * param) {
	vmem_server_loop(param);
	return NULL;
}

void * router_task(void * param) {
	while (1) {
		csp_route_work();
	}
	return NULL;
}

uint32_t serial_get(void) {
    return 0;
}

int main() {
    csp_init();

    csp_bind_callback(csp_service_handler, CSP_ANY);
    csp_bind_callback(param_serve, PARAM_PORT_SERVER);

    static pthread_t vmem_server_handle;
    pthread_create(&vmem_server_handle, NULL, &vmem_server_task, NULL);

    static pthread_t router_handle;
    pthread_create(&router_handle, NULL, &router_task, NULL);

    while (1) {} // main loop
}
```

Furthermore, we'll want to add an interface to the CSP network. For this example, we'll be using one of the defaults based on the ZeroMQ asynchronous messaging library, and exposing our application as node 1 on the network. 
```c
// (...)
#include <csp/interfaces/csp_if_zmqhub.h>

// (...)

int main() {
    csp_iface_t * iface;
	csp_zmqhub_init_filter2("ZMQ", "localhost", 1, 8, false, &iface, NULL, CSP_ZMQPROXY_SUBSCRIBE_PORT, CSP_ZMQPROXY_PUBLISH_PORT);

	iface->is_default = true;
	iface->addr = 1;
	iface->netmask = 8;
	iface->name = "ZMQ";

    // (...)
}
```

Finally, we will want to define and store some parameters on this node. Let's define some parameters that allow us to run the [Fibonacci sequence example procedure](example_procedures.md#fibonacci-sequence).

```c
// (...)
#include <vmem/vmem.h>
#include <vmem/vmem_ram.h>
#include <param/param.h>

extern vmem_t vmem_config;
VMEM_DEFINE_STATIC_RAM(config, "config", 42);

uint32_t _n, __zero, _rx0, _rx1, _rx2;

PARAM_DEFINE_STATIC_RAM(1, n, PARAM_TYPE_UINT32, -1, 0, PM_CONF, NULL, "", &_n, "");
PARAM_DEFINE_STATIC_RAM(2, _zero, PARAM_TYPE_UINT32, -1, 0, PM_CONF, NULL, "", &__zero, "");
PARAM_DEFINE_STATIC_RAM(3, rx0, PARAM_TYPE_UINT32, -1, 0, PM_CONF, NULL, "", &_rx0, "");
PARAM_DEFINE_STATIC_RAM(4, rx1, PARAM_TYPE_UINT32, -1, 0, PM_CONF, NULL, "", &_rx1, "");
PARAM_DEFINE_STATIC_RAM(5, rx2, PARAM_TYPE_UINT32, -1, 0, PM_CONF, NULL, "", &_rx2, "");

// (...)

int main() {
    // (...)
}
```

Note that it's normally recommended to expose more general parameters such as an array of uint32 to act as a general purpose register for intermediate calculations. These parameter definitions simply make the example procedure easier to understand.

### Build setup
We'll be using Meson to build the application. The following `meson.build` file should be sufficient to build the application, assuming all source code is in the `main.c` file and `libcsp` + `libparam` are available in the `lib` subdirectory as `csp` and `param` respectively

```meson
project('csp-proc-demo', 'c', subproject_dir: 'lib', default_options: [
	'buildtype=release', 
	'c_std=gnu11', 
	'b_lto=false',
	'default_library=static',
	'param:list_dynamic=true'
])

sources = files(['main.c'])

deps = []
deps += dependency('csp', fallback: ['csp', 'csp_dep'])
deps += dependency('param', fallback: ['param', 'param_dep'])

csp_proc_demo = executable('csp-proc-demo', sources,
	dependencies : deps,
	install : true,
	link_args : ['-Wl,--export-dynamic', '-ldl'],
)
```

## Integrating `csp_proc`
Integrating `csp_proc` into the application is as simple as adding the following lines to the `main` function. This will start the `csp_proc` server on the node (depending on the work being done by `libcsp`) and allow you to run procedures on it.

```c
// (...)
#include <csp_proc/proc_server.h>

// (...)

int main() {
    // (...)

    proc_server_init();
    csp_bind_callback(proc_serve, PROC_PORT_SERVER);

    // (...)
}
```

The `PROC_PORT_SERVER` is an arbitrary default port defined in `csp_proc` that the server listens on. This can be changed to any other port if needed (but this must naturally align with the client-side code).

### Build setup with `csp_proc`
To build the application with `csp_proc`, you'll need to add the `csp_proc` dependency to the `meson.build` file. This can be done by adding the following line to the `deps` list and specifying a few options (assuming `csp_proc` is available in the `lib` subdirectory):

```meson
project((...), default_options: [
    (...)
    'csp_proc:posix=true',
    'csp_proc:proc_runtime=true',
    (...)
])

(...)

deps += dependency('csp_proc', fallback: ['csp_proc', 'csp_proc_dep']).as_link_whole()

(...)
```

Remember to add `.as_link_whole()` to the dependency to avoid link-time optimization issues.

## Running procedures
You can now build and run the application, after which your node will be available on the network and ready to run procedures. To interact with the network, setup a simple client e.g. using the `slash` commands provided by `csp_proc`. Refer to [discosat/csh](https://github.com/discosat/csh) for an example client implementation. The build setup in that repository also provides utility called `zmqproxy` that can be used to connect the nodes together. In summary, when everything is compiled, you can run the following commands to start the application and connect to the network:

```sh
./csp-proc-demo & # in build directory of csp-proc-demo
./zmqproxy & # in build directory of discosat/csh  
./csh # in build directory of discosat/csh which
```

from the `csh` prompt, you can now run the following commands to finish the CSP setup:

```sh
csp init
csp add zmq -d 2 localhost # add client as node 2 on the network
# run `csp scan` or `ping 1` to verify the connection
```

You should now be able to see node 1 in the network and run procedures on it. For example, you can set up and run the Fibonacci sequence procedure by running the following commands:

```sh
# set the active node to node 1 for implicit node argument
node 1

# procedure 0 (initialization)
proc new
proc set _zero 0
proc set rx0 0
proc set rx1 1
proc ifelse n > _zero
proc call 69

proc push 42

# procedure 1 (calculation)
proc new
proc binop rx0 + rx1 rx2
proc unop rx1 idt rx0
proc unop rx2 idt rx1
proc unop n -- n
proc ifelse n == _zero
proc noop
proc call 69

proc push 69

# Everything is now set up. Provide an argument for n and run the procedure. Make sure to download the parameter list first to be able to set n directly.
list download
set n 10
proc run 42

# The result can be read from the rx0 parameter
get rx0  # returns 55
```
