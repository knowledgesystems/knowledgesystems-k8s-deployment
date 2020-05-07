# Temp Webinar instance

For the webinar series we've been increasing the compute power temporarily. Specifically the webinar deployment in this folder is for the presenter to use so even if production goes down things can still go on as usual.

These are the steps to increase overall compute power and set up the temp webinar instance:

1. Create **2** new db instances on AWS RDS
    - Go to RDS page, click on snapshots, click on System, pick last public snapshot, click on action >
      restore
    - Select a big database, i usually double it: db.r5.4xlarge
    - set security group is to allow connections from anywhere (or the k8s nodes). rds-launchwizard-5 seems to work. Prolly good to rename. I guess anything that allows 3306 access to the relevant IPs
    - mysql conf should be the same as production db (that is it allows bigger packets etc). It's called cbioportla-mysql-conf or something. It should be on this one already if u restore but good to double check
    - everything else can stay at default
    - Create another instance in the same way. This way both the webinar instance and the public instance can have their own overpowered db instance.
2. Increase number of nodes in large-mem group from 4 -> 6. This is the group of nodes that cbioportal runs on (see [../cbioportal_spring_boot.yaml](../cbioportal_spring_boot.yaml)). Note that you need to be able to use kops for thiss:
    ```
    kops edit instancegroups large-mem
    kops update cluster
    # check output of update cluster, it should only add more nodes
    # then apply the changes with
    kops update cluster --yes
    ```
    (Optional) increase those for genome-nexus group as well from 2 -> 4 in the same way
3. Point db host parameters in this folder to the newly setup AWS RDS node
4. `kubectl apply -f cbioportal_webinar.yaml` to bring up the webinar instance. URL has already been configure
5. Point [../cbioportal_sprint_boot.yaml](../cbioportal_sprint_boot.yaml) to use the newly setup AWS RDS node (should be different from 3.)
5. (optional) increase number of replicas for [../cbioportal_sprint_boot.yaml](../cbioportal_sprint_boot.yaml)
6. (optional) increase number of replicas for [../../genome-nexus/gn_spring_boot.yaml](../../genome-nexus/gn_spring_boot.yaml)


NOTE: if you are setting up a new URL (i.e. other than webinar.cbioportal.org) make sure to add it to the allowed redirects in google auth
