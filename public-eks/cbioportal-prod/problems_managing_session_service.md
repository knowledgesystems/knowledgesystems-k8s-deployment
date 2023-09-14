# cBioPortal

## Session service

In April 2023, an attempt was made to adjust the nodeSelector for the cbioportal session service mongoDB installation for the public portal. It was abandoned after encountering a number of difficulties.

* the version of mongodb which we are running was installed originally with an older version of helm than what we are currently running. It is suspected that we have lost track of which version was used.
* problems were reported with the cluster configuration parameters and the persistence mode, but even after attempting to set (--set persistence.accessMode=ReadWriteOnce) or disable persistence alltogether, errors were still seen when attempting to install the chart:

Here is a rough timeline:
1. the installations were not visible in the helm v3 client we have upgraded to, so helm cli 2.12.2 was installed
1. the bitnami charts were relocated (possibly more than once), so the new chart repository for backwards compatibility was added (bitnami-full-index) and then the version of the helm chart (4.0.4) was able to be found. (helm2 repo add bitnami-full-index https://raw.githubusercontent.com/bitnami/charts/archive-full-index/bitnami)
1. the chart still failed to install because a required value was unset: helm2 install --name test-mission-critical-mongo bitnami-full-index/mongodb --version 4.0.4 --set persistence.size=1Gi --set tolerances=mission-critical --set nodeselector=mission-critical --> Error: release test-mission-critical-mongo failed: PersistentVolumeClaim "test-mission-critical-mongo-mongodb" is invalid: spec.accessModes: Unsupported value: "<nil>": supported values: "ReadOnlyMany", "ReadWriteMany", "ReadWriteOnce". The setting was added.
1. the chart still failed to install: helm2 install --name test-mission-critical-mongo bitnami-full-index/mongodb --version 4.0.4 --set persistence.size=1Gi --set tolerances=mission-critical --set nodeselector=mission-critical --set spec.accessModes=ReadWriteMany --set persistence.accessMode=ReadWriteOnce --> Error: release test-mission-critical-mongo failed: persistentvolumeclaims "test-mission-critical-mongo-mongodb" already exists. Thinking that maybe volumes are not properly disposed of when helm installations are deleted, a new name for the installation was attempted.
1. a fresh install under a new release name (used for the first time) also failed with the same "persistent volume clame exists" error: helm2 install --name test-mission-critical-mongo2 bitnami-full-index/mongodb --version 4.0.4 --set persistence.size=1Gi --set tolerances=mission-critical --set nodeselector=mission-critical --set spec.accessModes=ReadWriteMany --set persistence.accessMode=ReadWriteOnce --> Error: release test-mission-critical-mongo2 failed: persistentvolumeclaims "test-mission-critical-mongo2-mongodb" already exists

At this point, the attempt to install (for testing of upgrade) mongodb of the currently deployed version (4.0.4) was abandoned. A general upgrade of helm / kubernetes and mongo was contemplated.
```
