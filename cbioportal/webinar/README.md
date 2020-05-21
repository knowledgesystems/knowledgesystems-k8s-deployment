# Temp Webinar instance

For the webinar series we've been increasing the compute power temporarily. Specifically the webinar deployment in this folder is for the presenter to use so even if production goes down things can still go on as usual.

These are the steps to increase overall compute power and set up the temp webinar instance:

1. Create **2** new db instances on AWS RDS
    - Go to RDS page, click on snapshots, click on System, pick last public snapshot, click on action >
      restore
    - Select a big database, i usually double it: db.r5.4xlarge. If expecting very big load try even bigger, e.g. db.r5.12xlarge
    - set security group is to allow connections from anywhere (or the k8s nodes). rds-launchwizard-5 seems to work. Prolly good to rename. I guess anything that allows 3306 access to the relevant IPs
    - mysql conf should be the same as production db (that is it allows bigger packets etc). It's called cbioportla-mysql-conf or something. It should be on this one already if u restore but good to double check
    - everything else can stay at default
    - Create another instance in the same way. This way both the webinar instance and the public instance can have their own overpowered db instance.
    
**NOTE: it takes a long time for the database to boot (~30m), so you can continue with next non-database related steps**

2. After creation of database instances modify them to enable "performance insights" (not sure if one can do this during creation of the instances)
3. Increase number of nodes in large-mem group from 4 -> 6. This is the group of nodes that cbioportal runs on (see [../cbioportal_spring_boot.yaml](../cbioportal_spring_boot.yaml)). Note that you need to be able to use kops for thiss:
    ```
    kops edit instancegroups large-mem
    kops update cluster
    # check output of update cluster, it should only add more nodes
    # then apply the changes with
    kops update cluster --yes
    ```
    (Optional) increase those for genome-nexus group as well from 2 -> 4 in the same way
4. Point db host parameters in `cbioportal_webinar.yaml` to the newly setup AWS RDS node
5. `kubectl apply -f cbioportal_webinar.yaml` to bring up the webinar instance. URL has already been configured
6. Point [../cbioportal_sprint_boot.yaml](../cbioportal_sprint_boot.yaml) to use the newly setup AWS RDS node (should be different from 3.)
7. (optional) increase number of replicas for [../cbioportal_sprint_boot.yaml](../cbioportal_sprint_boot.yaml)
8. (optional) increase number of replicas for [../../genome-nexus/gn_spring_boot.yaml](../../genome-nexus/gn_spring_boot.yaml)


NOTE: if you are setting up a new URL (i.e. other than webinar.cbioportal.org) make sure to add it to the allowed redirects in google auth

## Live monitoring
For monitoring during the webinar I have a few windows/terminals open with following things running

### Terminal

- watch kubectl get po

to see if all pods are alive

- watch kubectl get po --namespace=genome-nexus

see pods in genome nexus namespace

### Browser windows:

- cBioPortal Dashboard https://grafana.cbioportal.org/d/7R5LYe_iz/cbioportal-ingress-pod-stats?refresh=5s&orgId=1
- Genome Nexus Dashboard https://grafana.cbioportal.org/d/vWTDoH6Wz/genome-nexus?refresh=5s&orgId=1

For both of those, if u see memory spike a lot you can e.g. manually delete one of the pods with `kubectl delete po` to make sure the pods don't crash at the same time. Triggering a restart for the entire deployment can be helpful as well: `kubectl set env deployment cbioportal-spring-boot --env="LAST_RESTART=$(date)"`

- Google Analytics https://analytics.google.com/analytics/web/?authuser=1#/realtime/rt-overview/a17134933w34760563p34065145/    
Nice way to see how many people are active on the site

- The webinar itself

Of course you'll want to listen to the webinar itself to hear if anything crashed live on air :)
