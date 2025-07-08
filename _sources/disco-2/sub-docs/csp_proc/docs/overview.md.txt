# csp_proc

Lightweight, programmable procedures with a libcsp- and libparam-native runtime. This provides remote control of libparam-based coordination between nodes in a CSP network, essentially exposing the network as single programmable unit.

The library has a relatively small footprint suitable for microcontrollers, requiring no external libraries other than libcsp and libparam themselves for the core of the library. As of writing, the library provides 2 default runtime implementations which depend on FreeRTOS and POSIX respectively. See also [usage examples](usage_examples/index.md) for a demonstration of the commands available in the DSL.

## DSL Overview

`csp_proc` provides a set of slash commands that allow users to create, manage, and execute procedures on a given CSP node. The procedures facilitate control-flow and arithmetic operations while remaining small - usually on the order of hundreds of bytes! The runtime is detached from the DSL, allowing customizations, and there is support for pre-programmed, complex procedures on the native platform in reserved procedure slots. The following is a list of commands available in the DSL:

### Procedure Management Commands

- `proc new`: Creates a new procedure and sets it as the active procedure context.
- `proc del <procedure slot> [node]`: Deletes the procedure in the specified slot (0-255) on the node. Note that some slots may be reserved for predefined procedures.
- `proc pull <procedure slot> [node]`: Switches the active procedure context to the procedure pulled from the specified slot (0-255) on the node.
- `proc push <procedure slot> [node]`: Pushes the active procedure to the specified slot on the node.
- `proc size`: Returns the size (in bytes) of the active procedure.
- `proc pop [instruction index]`: Removes the instruction at the specified index (defaults to the latest instruction) in the active procedure.
- `proc list`: Lists the instructions in the active procedure.
- `proc slots [node]`: Lists the occupied procedure slots on the node.
- `proc run <procedure slot> [node]`: Executes the procedure in the specified slot.

### Control-Flow and Arithmetic Operations

The following commands allow the user to program control-flow and arithmetic operations within procedures. The result is always a libparam parameter stored on the node hosting the corresponding procedure server (node 0 from its perspective) and `[node]` is the node on which the operands are located - Except when using the `rmt` unop operation, where it's switched!

- `proc block <param a> <op> <param b> [node]`: Blocks execution of the procedure until the specified condition is met. `<op>` can be one of: `==`, `!=`, `<`, `>`, `<=`, `>=`.
- `proc ifelse <param a> <op> <param b> [node]`: Skips the next instruction if the condition is not met, and the following instruction if it is met. This command cannot be nested in the default runtime - i.e. it cannot be used again within the following 2 instructions.
- `proc noop`: Performs no operation. Useful in combination with `ifelse` instructions.
- `proc set <param> <value> [node]`: Sets the value of a parameter. The type of value is always inferred from the libparam type of the parameter.
- `proc unop <param> <op> <result> [node]`: Applies a unary operator to a parameter and stores the result. `<op>` can be one of: `++`, `--`, `!`, `-`, `idt`, `rmt`. `idt` and `rmt` are both identity operators.
- `proc binop <param a> <op> <param b> <result> [node]`: Applies a binary operator to parameters `<param a>` and `<param b>` and stores the result. `<op>` can be one of: `+`, `-`, `*`, `/`, `%`, `<<`, `>>`, `&`, `|`, `^`.
- `proc call <procedure slot> [node]`: Inserts an instruction to run the procedure in the specified slot.
