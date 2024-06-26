Flight planning (`csp_proc`)
======================


`csp_proc` is the library responsible for low-level flight planning / orchestration of the CSP nodes for scientific observations. It provides a set of general instructions that can be used to set libparam parameters with simple synchronization and conditional logic. The library is described in more detail on its own documentation page at https://discosat.github.io/csp_proc/ - which is also embedded as the following sub-pages.

.. toctree::
   :maxdepth: 2
   
   ../sub-docs/csp_proc/index
   ../sub-docs/csp_proc_function_reference.rst
   

In the context of DISCO-II, `csp_proc` lives on the Cortex-M7 node, and the parameters it exposes can be seen on the `Cortex-M7 <cortex-m7.html>`_ page.

A simple observation sequence based on time might simply look like the following. Nodes are abbreviated so ``$M7`` is the Cortex-M7 node, ``$A53`` is the Cortex-A53 node, ``$CAM`` is the camera control node and ``$DIPP`` is the image processing node.

.. code::

   proc new

   # [START] Observation procedure
   proc set p_uint32[0] 1744407764 $M7  # This is the GNSS time we want to start the observation
   proc block gnss_time >= p_uint32[0] $M7
   proc set wake_a53 1 $M7

   proc set p_uint8[0] 1 $M7  # Use GPR for following comparison
   proc block a53_status == p_uint8[0] $M7
   proc set mng_camera_control $CAM $A53  # Start camera control node
   proc set mng_dipp $DIPP $A53  # Start image processing node

   proc unop gnss_time idt p_uint32[1] $M7  # Log the time of the observation

   proc set capture_param "CAMERA_TYPE=VMB;CAMERA_ID=1800 U-2040c;NUM_IMAGES=1;EXPOSURE=55000;ISO=0;" $CAM  # Take a single image
   proc set pipeline_run 1 $DIPP  # Run image processing pipeline
   proc set p_uint8[1] 0 $M7  # Use GPR for following comparison
   proc block pipeline_run == 0 $DIPP  # Wait for image processing to finish

   # Optionally kill camera control and dipp processes
   proc set mng_camera_control 0 $A53  # Stop camera control node
   proc set mng_dipp 0 $A53  # Stop image processing node

   proc set suspend_a53 1 $A53  # Suspend A53 node
   # [END] Observation procedure

   proc push 42 $M7
   proc run 42 $M7
