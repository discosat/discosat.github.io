# Geo-fencing
In this example, we will imagine a scenario where a vehicle is equipped with a GNSS module exposed via libparam parameters on node 1, and node 2 has some active component that needs to be controlled based on the vehicle's position, e.g. a sensor logging a data point when the vehicle enters a certain area. The following is a sequence of commands that can be used to implement a simple geo-fencing procedure based on manhattan distance from a fixed point. For this example, it's assumed that node 1 has the libparam parameters: `lat` (double), `lon` (double) from the GNSS module along with `lat_diff` (double), `lon_diff` (double), `dist` (double) and `geo_check` (uint8) to store intermediate results, and `target_lon` (double) `target_lat` (double), `max_dist` (double) to determine the geo-fencing area. Node 2 has a `sensor_log` (uint8) parameter with a callback attached to trigger the logging of a data point.
```bash
# procedure 0 (geo-fencing setup)
proc new

proc binop lat - target_lat lat_diff 1  # calculate latitude difference
proc ifelse lat_diff < 0 1  # negate if negative
proc unop lat_diff - lat_diff 1
proc noop

proc binop lon - target_lon lon_diff 1 # calculate longitude difference
proc ifelse lon_diff < 0 1  # negate if negative
proc unop lon_diff - lon_diff 1
proc noop

proc binop lat_diff + lon_diff dist 1
proc ifelse dist < max_dist 1  # check if the vehicle is within range
proc set geo_check 1 1  # geo_check signals the vehicle is within the area
proc set geo_check 0 1  # geo_check signals the vehicle is outside the area
proc call 0 1 # call itself recursively to keep checking the vehicle's position

proc push 0 1  # push the procedure to slot 0 on node 1

# procedure 1 (geo-fencing check)
proc new
proc block geo_check == 1 1  # block until vehicle is within the area
proc set sensor_log 1 2  # log a data point
# optionally call itself recursively if the sensor should keep logging data points while the vehicle is in the area
proc call 1 2

proc push 1 1  # push the procedure to slot 1 on node 1
```
Note that the last integer argument in the `proc` commands is the node on which the operands are located. The procedures themselves should be pushed onto the same node hosting a procedure server, which is assumed to be node 1 in this case.

The following commands can now be executed to set up and run the location-based logging procedure:
```bash
node 1
set target_lat 55.6761
set target_lon 12.5683
set max_dist 0.01
proc run 0  # Run the procedure to update the geo_check parameter
proc run 1  # Run the procedure to log data points when the vehicle is within the area
```

One can then imagine an extended scenario where there is e.g. a third node responsible for some actuator that must react based on the sensor node, which adds another layer of coordination to the system - all this can be orchestrated using the DSL!

## Utilizing reserved, pre-programmable procedure slots
There is also support for pre-programmed procedures in reserved slots, which can be used to simplify the DSL code or take care of more complex operations. For example, one can write a function compiled into the application on node 1 that calculates the euclidean distance between points defined by (`lat`, `lon`) and (`target_lat`, `target_lon`) and stores the result in the `dist` parameter. For the sake of example, let's assumed this procedure is available in slot 0. Then the geo-fencing setup procedure can be simplified as follows:
```bash
# procedure 1 (geo-fencing setup)
proc new
proc call 0 1  # call the pre-programmed procedure to calculate `dist`
proc ifelse dist < max_dist 1  # check if the vehicle is within range
proc set geo_check 1 1  # geo_check signals the vehicle is within the area
proc set geo_check 0 1  # geo_check signals the vehicle is outside the area
proc call 1 1  # call itself recursively to keep checking the vehicle's position

proc push 1 1  # push the procedure to slot 1 on node 1
```

The (geo-fencing check) procedure can then simply be adjusted to account for the new procedure slot. To demonstrate more functionality, we can do this by running the following slash commands before redefining and pushing the procedure above.

```bash
node 1  # set the active node to node 1 for implicit node argument

proc pull 1  # pull the pre-programmed procedure from slot 1
proc pop  # remove the last instruction in the procedure
proc call 2  # replace the call instruction to point to new slot

proc push 2  # push the procedure to slot 2
```

# Fibonacci Sequence
While using the DSL to calculate Fibonacci numbers certainly isn't the intended use of the DSL (nor efficient), it serves as a good example to demonstrate the capabilities of the DSL. The following is a sequence of commands that can be used to calculate the Fibonacci sequence up to the $n$-th term:
```bash
# procedure 0 (initialization)
proc new
proc set _zero 0  # initialize the _zero parameter
proc set rx0 0  # initialize register 0 to hold the n-th term
proc set rx1 1  # initialize register 1 to hold the (n+1)-th term
proc ifelse n > _zero  # only work to do if n > 0
proc call 1  # call procedure 1, defined below

proc push 0  # push the procedure to slot 0

# procedure 1 (calculation)
proc new
proc binop rx0 + rx1 rx2  # calculate the (n+2)-th term
proc unop rx1 idt rx0  # shift the registers one term with identity operator
proc unop rx2 idt rx1
proc unop n -- n  # decrement n
proc ifelse n == _zero
proc noop  # if-clause: condition is met
proc call 1  # else-clause: condition is not met (recurse in this case)

proc push 1  # push the procedure to slot 1
```

E.g. to calculate the 10th term of the Fibonacci sequence, the following commands can now be executed:
```bash
set n 10
proc run 0
```
After which the 10th term of the Fibonacci sequence can be read from the `rx0` register (which is really just the `rx0` libparam parameter).
```bash
get rx0
```
Naturally, this assumes `n`, `_zero`, `rx0`, `rx1`, and `rx2` are available as integer libparam parameters on the node. Also note that with the default FreeRTOS-based runtime, it is recommended to divide complex routines into small units of work, where any calls to other procedures are done in the last instruction (or second-last if preceded by ifelse) to avoid nesting function calls.
