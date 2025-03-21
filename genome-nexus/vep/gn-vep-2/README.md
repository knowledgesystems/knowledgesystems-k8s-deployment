# Options for setting up VEP

## Easist (Currently in production)

The current solution achieves performance comparable to the Ensembl Public API. Simply apply the `gn_vep_2.yaml` config (or `gn_vep_2_extended.yaml` for AlphaMissense and PolyPhen/SIFT predictions), and make sure to supply the database credentials through a ConfigMap. Our current production setup connects to an RDS instance.

## Max Performance

To maximize performance in the simplest possible way, use `mysql.yaml` along with `gn_vep_2_pv.yaml`. The MySQL file is responsible for running the MySQL pod, while the Local PV (Persistent Volume) file allows for persistent storage of the data.

However, there is a drawback when using this approach: We are limited to one replica of the MySQL pod. Since the persistent volume mounts `/var/lib/mysql` to achieve data persistence, this imposes another limit: resource contention. MySQL is set up with locking mechanisms that do not allow another replica to mount this directory, which may cause scalability concerns if read replicas are needed.

## Max Performance and Scalable

While not implemented yet, a solution that may allow us to achieve performance and scalability may already exist: [MySQL Operator for Kubernetes](https://dev.mysql.com/doc/mysql-operator/en/). This solution should handle scaling our MySQL pods by cloning the volume for each read replica. Since the VEP data is ~15GB, this should not be a concern as disk storage is relatively cheap.

# Loading the data

In any of the above solutions it will be necessary to load in the data using the MySQL client. You must first create the database `homo_sapiens_core_{DATA_VERSION}_{37|38}`. You can then use the MySQL client to import the data from a data dump. 

To obtain the data folloe the instructions for [Setting up Genome Nexus VEP](https://github.com/genome-nexus/genome-nexus-vep/blob/master/README.md).