# Setup `csp_proc`

The easiest way to integrate `csp_proc` is with [meson](https://mesonbuild.com/). As of writing, no other build systems are supported out-of-the-box, so you'll have to get creative if using meson is not an option. See below for an overview of the constituent parts of `csp_proc`.

The following demonstrates the outline of a `meson.build` file in a parent project where `libcsp`, `libparam`, and `csp_proc` are present in the `lib` subdirectory:
```meson
project(..., subproject_dir: 'lib', default_options: [
	'csp_proc:slash=false',
	'csp_proc:freertos=false',
	'csp_proc:posix=true',
	'csp_proc:proc_runtime=true',
	'csp_proc:RESERVED_PROC_SLOTS=...',
    ...
])

deps = []
deps += dependency('csp', fallback: ['libcsp', 'csp_dep'])
deps += dependency('param', fallback: ['libparam', 'param_dep'])
deps += dependency('csp_proc', fallback: ['csp_proc', 'csp_proc_dep']).as_link_whole()

app = executable(...
	dependencies : deps,
	...
)
```

Note that `csp_proc` is not a standalone library. The core part of the library depends on `libparam` and `libcsp`, while optional parts depend on `slash` and the FreeRTOS kernel or POSIX functionality. A reference setup can be found in the following [Dockerfile](https://github.com/discosat/csp_proc/blob/main/Dockerfile), which is the environment that's used to run the automated tests in the CI pipeline.

## Composition of the library
The library has the following components:
### Core
The core part of the library consists of the following files:
- _Optional_ `proc_analyze.(h|c)`: Functions for analyzing procedures (Will automatically be included if runtime is enabled)
- `proc_client.(h|c)`: Client-side functions, e.g. request to push procedure over CSP network.
- `proc_mutex.h`: Mutex for controlling access to relevant data structures.
	- `sync/proc_mutex_FreeRTOS.c`: FreeRTOS-specific mutex implementation.
	- `sync/proc_mutex_POSIX.c`: POSIX-specific mutex implementation.
- `proc_pack.(h|c)`: Functions for packing and unpacking procedures into CSP packets.
- `proc_runtime.h`: Runtime interface as expected by the core library.
- _Optional_`proc_server.(h|c)`: Server-side functions, e.g. handling incoming procedure requests (Will automatically be included if procedure storage is enabled)
- `proc_store.h`: Functions for storing and retrieving procedures in a local procedure table.
- `proc_types.h`: Procedure data type, including the procedure structure and the instruction structure.

### Storage
- _Optional_ `proc_store_dynamic.h`: Procedure storage using dynamic memory allocation.
- _Optional_ `proc_store_static.h`: Procedure storage using static memory allocation.

### Runtime
- _Optional_ `runtime/proc_runtime_FreeRTOS.c`: FreeRTOS-based runtime for `csp_proc`.
- _Optional_ `runtime/proc_runtime_instructions_FreeRTOS.c`: FreeRTOS-specific instruction handlers.
- _Optional_ `runtime/proc_runtime_POSIX.c`: POSIX-based runtime for `csp_proc`.
- _Optional_ `runtime/proc_runtime_instructions_POSIX.c`: POSIX-specific instruction handlers.
- _Optional_ `runtime/proc_runtime_instructions.c`: Default platform-agnostic instruction handlers.

### Slash
- _Optional_ `slash/slash_csp_proc.c`: A series of slash commands for interacting with `csp_proc`.


## Configuration options at compile-time

The following options can be configured at compile-time:

- `RESERVED_PROC_SLOTS`: This option defines the number of reserved procedure slots.
- `MAX_PROC_BLOCK_TIMEOUT_MS`: This option sets the maximum time (in milliseconds) that block instructions will wait before timing out.
- `MIN_PROC_BLOCK_PERIOD_MS`: This option sets the minimum time (in milliseconds) between evaluations of a block instruction's condition.
- `MAX_PROC_RECURSION_DEPTH`: This option sets the maximum recursion depth of a procedure.
- `MAX_PROC_CONCURRENT`: This option sets the maximum number of procedure runtimes that can run concurrently.

In addition to the above, the default runtime implementations have their own set of configuration options:

- `PARAM_REMOTE_TIMEOUT_MS`: This option sets the timeout (in milliseconds) for a remote call via libparam.
- `PARAM_ACK_ON_PUSH`: This option toggles whether to expect an acknowledgment from the remote node when pushing a parameter.
- `PROC_FLOAT_EPSILON`: This option sets the epsilon value for floating-point comparisons.

And the FreeRTOS-based runtime has the following additional options:

- `PROC_RUNTIME_TASK_SIZE`: This option sets the stack size of a runtime task.
- `PROC_RUNTIME_TASK_PRIORITY`: This option sets the FreeRTOS task priority of a runtime task.
- `TASK_STORAGE_RECURSION_DEPTH_INDEX`: This option sets the index of the thread-local storage pointer for recursion depth tracking.

Please note that the FreeRTOS-based runtime requires a `FreeRTOSConfig.h` file in the parent project. This configuration file should define `configNUM_THREAD_LOCAL_STORAGE_POINTER` to a value greater than 0, as the tracking of recursion depth is done using thread-local storage.

Lastly, the library has the following meson build options:

- `slash` (boolean, default: `false`): Build slash.
- `freertos` (boolean, default: `false`): Build for FreeRTOS system.
- `posix` (boolean, default: `true`): Build for POSIX system.
- `proc_runtime` (boolean, default: `false`): Build the runtime module.
- `proc_analysis` (boolean, default: `false`): Build the analysis module.
- `proc_store_static` (boolean, default: `false`): Build the proc store with static memory allocation.
- `proc_store_dynamic` (boolean, default: `true`): Build the proc store with dynamic memory allocation.
