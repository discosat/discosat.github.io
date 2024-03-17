# Image Processing Pipeline
The DISCO-2 Image Processing Pipeline (DIPP) is build as a configurable and extendable image processing pipeline that facilitates remote reconfiguration and reordering of individual modules in the pipeline to provide a flexible solution for diverse imaging needs. Each module is seen as fully self-contained image processing environment which has all its dependencies statically compiled inside.

## Overview
The image processing pipeline is to process images from the camera, before they are downlinked to the ground station. The main objective is to filter away bad data to optimize the utilization of the limited downlink bandwidth. The image filtering takes place within different image processing modules in the pipeline.

The image processing pipeline and the camera communicate though the use of [System V Shared Memory](https://docs.oracle.com/cd/E19683-01/816-5042/svipc-41256/index.html) and a [System V Message Queue](https://docs.oracle.com/cd/E19683-01/816-5042/svipc-23310/index.html). The camera will take images in bursts, and batch the data from the raw images together such that each image from the burst will be stored contiguously in a `unsigned char *data` array, which will be located inside a shared memory segment which has been created exclusively for the given image batch. In-between the contiguous image data, a 32-bit integer will be stored which indicates the size of the following image in the data. The image data sizes will be utilized for iterating through the the images in the batch, as the image size indicates how many bytes to skip ahead, in order to reach the next image in the batch. An example of some batched image data can be seen below:
```c
// Example buffer containing image data
unsigned char buffer[] = {
    5, 0, 0, 0, 'i', 'm', 'a', 'g', 'e',     // 4 bits allocated for the size of image 0 followed by image data
    3, 0, 0, 0, 'f', 'o', 'o',               // 4 bits allocated for the size of image 1 followed by image data
    6, 0, 0, 0, 'b', 'a', 'r', 'b', 'a', 'z' // 4 bits allocated for the size of image 2 followed by image data
};
```

The camera will construct some metadata about the saved image batch data, which will be sent to the pipeline through a System V Message Queue, utilizing 71 as the queue key. The metadata will be stored in the following struct:
```c
typedef struct ImageBatch {
    long mtype;          /* message type to read from the message queue */
    int height;          /* height of images */
    int width;           /* width of images */
    int channels;        /* channels of images */
    int num_images;      /* amount of images */
    int batch_size;      /* size of the entire image batch of data */
    int shm_key;         /* key to shared memory segment of image data */
    int pipeline_id;     /* id of pipeline to utilize for processing */
    unsigned char *data; /* address to image data (in shared memory) */
} ImageBatch;
```

The `ImageBatch` struct contains information about the images in the batch, such as their width, height, amount of channels and amount of images. The `ImageBatch` struct will also contain a pointer to the shared memory segment, where the raw image data is stored.

While processing the raw image data, the pipeline modules will modify the image data from shared memory and either reuse the same shared memory segment, or create a new shared memory segment if the new image data don't fit into the old segment. When a module finishes it updates the data in the `ImageBatch` struct, and updates the pointer to the shared memory segment, if it has changed. Hereafter the`ImageBatch` struct is passed onto the next module in the pipeline.

In order to ensure isolation and fault-tolerance, each module will be executed in a child-process forked by the main pipeline process. The main process will supervise the execution of the child-processes and fail gracefully if a module encounters a failure (e.g. encounters a runtime exception). The image batch structs are sent back and fourth in-between modules through the use of `pipes` which enable secure and isolated data transfer between different memory spaces. This method not only keeps the module outputs separate, but also provides a checkpoint for the supervisor (main process) to verify the successful completion of the child’s task.

The pipeline and the modules are configured through CSP where configurations are sent to the pipeline using generic [Protobuf](https://protobuf.dev/) schemas which hold the required information. The configurations are made, and sent, using our CSH extension service described in [the following section](#configuring-the-pipeline).

An overview of how the module execution and configuration takes place, and how the pipeline interacts with the camera, can be seen in: (insert overview image)

## Configuring the Pipeline
Setting up DIPP involves defining the sequence and parameters of processing modules. Configuration can be performed remotely to tailor the pipeline to specific project requirements without direct access to the deployment environment. Two primary functions (`ippc pipeline [options] <pipeline-idx> <config-file>` and `ippc module [options] <module-idx> <config-file>`) are introduced as CSH extensions that enables the reconfiguration of the pipeline and individual modules. The source code and setup for the pipeline CSH extension are available on [github.com/Lindharden/csp_ippc](https://github.com/Lindharden/csp_ippc). The two commands are described in more details in [Command 1](#command-1-ippc-pipeline) and [Command 2](#command-2-ippc-module)

### Command 1: `ippc pipeline`

This command updates what modules are to be active in the specified pipeline.
Specify id of pipeline and yaml config file (relative path).
Node should be given by \<env\> using the node command.

Usage:

```
ippc pipeline [options] <pipeline-idx> <config-file>
```

Options:

- `-n, --node [NUM]`: node (default = \<env\>).
- `-t, --timeout [NUM]`: timeout (default = \<env\>).
- `-v, --paramver`: parameter system version (default = 2).
- `-a, --no_ack_push`: Disable ack with param push queue (default = true).

Example:
The below example updates the pipeline configuration for pipeline 1 on node 162 using the specified yaml file.

```
ippc pipeline -n 162 1 "pipeline_config.yaml"
```

Example of a valid pipeline configuration file:

```yaml
- order: 1
  param_id: 1
  name: classification
- order: 2
  param_id: 5
  name: superresolution
- order: 3
  param_id: 2
  name: compression
```
Note: A module included in multiple pipelines can be linked to different param_ids.

### Command 2: `ippc module`

This command updates the parameters for a specific pipeline module.
Specify id of module and yaml config file (relative path).
Node should be given by \<env\> using the node command.

Usage:

```
ippc module [options] <module-idx> <config-file>
```

Options:

- `-n, --node [NUM]`: node (default = \<env\>).
- `-t, --timeout [NUM]`: timeout (default = \<env\>).
- `-v, --paramver`: parameter system version (default = 2).
- `-a, --no_ack_push`: Disable ack with param push queue (default = true).

Example:
The below example update the parameters for module 2 on node 162 using the specified yaml file.

```
ippc module -n 162 2 "module_config.yaml"
```

Example of a valid module configuration file (see also the valid types):

```yaml
# Use following keys for type  #
#   bool    = 2                #
#   integer = 3                #
#   float   = 4                #
#   string  = 5                #

- key: param_name_1
  type: 2
  value: true

- key: param_name_2
  type: 3
  value: 256

- key: param_name_3
  type: 4
  value: 3.1415

- key: param_name_4
  type: 5
  value: DISCO
```

## Serialization of configurations
Protobuf schemas

## Running the Pipeline Binary

## Initiating Pipeline Processing

To initiate the pipeline, utilize the `pipeline_run` parameter on the CSP node through CSH. The `pipeline_run` parameter can be set to one of the following values, which determines the pipeline processing behavior.

| **_pipeline_run_ value** | **Batch processing procedure** | **Description**                                                                                         |
|--------------------------|--------------------------------|---------------------------------------------------------------------------------------------------------|
| 1                        | _PROCESS_ONE_                  | Process a single image batch.                                                                           |
| 2                        | _PROCESS_ALL_                  | Process all image batches in message queue.                                                             |
| 3                        | _PROCESS_WAIT_ONE_             | Wait for image batch to arrive in message queue. Then process one image batch.                          |
| 4                        | _PROCESS_WAIT_ALL_             | Wait for image batches to arrive in message queue. Then continuously process all arriving image batches. |

