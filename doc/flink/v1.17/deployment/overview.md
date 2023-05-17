# Deployment

Flink is a versatile framework, supporting many different deployment scenarios in a mix and match fashion.

Below, we briefly explain the building blocks of a Flink cluster, their purpose and available implementations. If you
just want to start Flink locally, we recommend setting up a [Standalone Cluster]().

## Overview and Reference Architecture

The figure below shows the building blocks of every Flink cluster. There is always somewhere a client running. It takes
the code of the Flink applications, transforms it into a JobGraph and submits it to the JobManager.

The JobManager distributes the work onto the TaskManagers, where the actual operators (such as sources, transformations
and sinks) are running.

When deploying Flink, there are often multiple options available for each building block. We have listed them in the
table below the figure.

![](images/deployment_overview.svg)

| **Component**                            | **Purpose**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | **Implementations**                                                                                                                                                                                                                                           |
|------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Flink Client                             | Compiles batch or streaming applications into a dataflow graph, which it then submits to the JobManager.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | * [Command Line Interface]()<br/>* [REST Endpoint]()<br/>* [SQL Client]()<br/>* [Python REPL]()                                                                                                                                                               |
| JobManager                               | JobManager is the name of the central work coordination component of Flink. It has implementations for different resource providers, which differ on high-availability, resource allocation behavior and supported job submission modes.<br/>JobManager [modes for job submissions:]()<br/>* **Application Mode**: runs the cluster exclusively for one application. The job's main method (or client) gets executed on the JobManager. Calling `execute`/`executeAsync` multiple times in an application is supported.<br/>* **Per-Job Mode**: runs the cluster exclusively for one job. The job's main method (or client) runs only prior to the cluster creation.<br/>* **Session Mode**: one JobManager instance manages multiple jobs sharing the same cluster of TaskManagers | * [Standalone]() (this is the barebone mode that requires just JVMs to be launched. Deployment with [Docker, Docker Swarm / Compose](), [non-native Kubernetes]() and other models is possible through manual setup in this mode)<br/>* Kubernetes<br/>* YARN |
| TaskManager                              | TaskManagers are the services actually performing the work of a Flink job.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |                                                                                                                                                                                                                                                               |
| -                                        | External Components (all optional)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | -                                                                                                                                                                                                                                                             |
| High Availability Service Provider       | Flink's JobManager can be run in high availability mode which allows Flink to recover from JobManager faults. In order to failover faster, multiple standby JobManagers can be started to act as backups.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | * [Zookeeper]()<br/>* [Kubernetes HA]()                                                                                                                                                                                                                       |
| File Storage and Persistency             | For checkpointing (recovery mechanism for streaming jobs) Flink relies on external file storage systems                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | See [FileSystems]() page.                                                                                                                                                                                                                                     |
| Resource Provider                        | Flink can be deployed through different Resource Provider Frameworks, such as Kubernetes or YARN.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | See [JobManager]() implementations above.                                                                                                                                                                                                                     |
| Metrics Storage                          | Flink components report internal metrics and Flink jobs can report additional, job specific metrics as well.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | See [Metrics Reporter]() page.                                                                                                                                                                                                                                |
| Application-level data sources and sinks | While application-level data sources and sinks are not technically part of the deployment of Flink cluster components, they should be considered when planning a new Flink production deployment. Colocating frequently used data with Flink can have significant performance benefits                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | For example:<br/>* Apache Kafka<br/>* Amazon S3<br/>* Elasticsearch<br/>* Apache Cassandra<br/>See [Connectors]() page.                                                                                                                                       |

### Repeatable Resource Cleanup

Once a job has reached a globally terminal state of either finished, failed or cancelled, the external component
resources associated with the job are then cleaned up. In the event of a failure when cleaning up a resource, Flink will
attempt to retry the cleanup. You can [configure]() the retry strategy used. Reaching the maximum number of retries
without succeeding will leave the job in a dirty state. Its artifacts would need to be cleaned up manually (see
the [High Availability Services / JobResultStore]() section for further details). Restarting the very same job (i.e.
using the same job ID) will result in the cleanup being restarted without running the job again.

There is currently an issue with the cleanup of CompletedCheckpoints that failed to be deleted while subsuming them as
part of the usual CompletedCheckpoint management. These artifacts are not covered by the repeatable cleanup, i.e. they
have to be deleted manually, still. This is covered by [FLINK-26606]().

## Deployment Modes

Flink can execute applications in one of three ways:

* in Application Mode,
* in a Per-Job Mode,
* in Session Mode.

The above modes differ in:

* the cluster lifecycle and resource isolation guarantees
* whether the application’s main() method is executed on the client or on the cluster.

![](images/deployment_modes.svg)

### Application Mode

In all the other modes, the application’s main() method is executed on the client side. This process includes
downloading the application’s dependencies locally, executing the main() to extract a representation of the application
that Flink’s runtime can understand (i.e. the JobGraph) and ship the dependencies and the JobGraph(s) to the cluster.
This makes the Client a heavy resource consumer as it may need substantial network bandwidth to download dependencies
and ship binaries to the cluster, and CPU cycles to execute the main(). This problem can be more pronounced when the
Client is shared across users.

Building on this observation, the Application Mode creates a cluster per submitted application, but this time, the
main() method of the application is executed on the JobManager. Creating a cluster per application can be seen as
creating a session cluster shared only among the jobs of a particular application, and torn down when the application
finishes. With this architecture, the Application Mode provides the same resource isolation and load balancing
guarantees as the Per-Job mode, but at the granularity of a whole application. Executing the main() on the JobManager
allows for saving the CPU cycles required, but also save the bandwidth required for downloading the dependencies
locally. Furthermore, it allows for more even spread of the network load for downloading the dependencies of the
applications in the cluster, as there is one JobManager per application.

In the Application Mode, the main() is executed on the cluster and not on the client, as in the other modes. This may
have implications for your code as, for example, any paths you register in your environment using the
registerCachedFile() must be accessible by the JobManager of your application.
Compared to the Per-Job mode, the Application Mode allows the submission of applications consisting of multiple jobs.
The order of job execution is not affected by the deployment mode but by the call used to launch the job. Using
execute(), which is blocking, establishes an order and it will lead to the execution of the “next” job being postponed
until “this” job finishes. Using executeAsync(), which is non-blocking, will lead to the “next” job starting before
“this” job finishes.

The Application Mode allows for multi-execute() applications but High-Availability is not supported in these cases.
High-Availability in Application Mode is only supported for single-execute() applications.

Additionally, when any of multiple running jobs in Application Mode (submitted for example using executeAsync()) gets
cancelled, all jobs will be stopped and the JobManager will shut down. Regular job completions (by the sources shutting
down) are supported.

### Per-Job Mode

Aiming at providing better resource isolation guarantees, the Per-Job mode uses the available resource provider
framework (e.g. YARN, Kubernetes) to spin up a cluster for each submitted job. This cluster is available to that job
only. When the job finishes, the cluster is torn down and any lingering resources (files, etc) are cleared up. This
provides better resource isolation, as a misbehaving job can only bring down its own TaskManagers. In addition, it
spreads the load of book-keeping across multiple JobManagers, as there is one per job. For these reasons, the Per-Job
resource allocation model is the preferred mode by many production reasons.

### Session Mode

Session mode assumes an already running cluster and uses the resources of that cluster to execute any submitted
application. Applications executed in the same (session) cluster use, and consequently compete for, the same resources.
This has the advantage that you do not pay the resource overhead of spinning up a full cluster for every submitted job.
But, if one of the jobs misbehaves or brings down a TaskManager, then all jobs running on that TaskManager will be
affected by the failure. This, apart from a negative impact on the job that caused the failure, implies a potential
massive recovery process with all the restarting jobs accessing the filesystem concurrently and making it unavailable to
other services. Additionally, having a single cluster running multiple jobs implies more load for the JobManager, who is
responsible for the book-keeping of all the jobs in the cluster.

### Summary

In Session Mode, the cluster lifecycle is independent of that of any job running on the cluster and the resources are
shared across all jobs. The Per-Job mode pays the price of spinning up a cluster for every submitted job, but this comes
with better isolation guarantees as the resources are not shared across jobs. In this case, the lifecycle of the cluster
is bound to that of the job. Finally, the Application Mode creates a session cluster per application and executes the
application’s main() method on the cluster.

## Vendor Solutions

A number of vendors offer managed or fully hosted Flink solutions. None of these vendors are officially supported or
endorsed by the Apache Flink PMC. Please refer to vendor maintained documentation on how to use these products.

### AliCloud Realtime Compute

[Website]()

Supported Environments: `AliCloud`

### Amazon EMR

[Website]()

Supported Environments: `AWS`

### Amazon Kinesis Data Analytics for Apache Flink

[Website]()

Supported Environments: `AWS`

### Cloudera DataFlow

[Website]()

Supported Environment: `AWS` `Azure` `Google` `On-Premise`

### Eventador

[Website]()

Supported Environment: `AWS`

### Huawei Cloud Stream Service

[Website]()

Supported Environment: `Huawei`

### Ververica Platform

[Website]()

Supported Environments: `AliCloud` `AWS` `Azure` `Google` `On-Premise`

