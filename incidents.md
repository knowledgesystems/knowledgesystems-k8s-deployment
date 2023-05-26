# Incidents Log
## 2023/05/24 Mongodb session service crash
- Issue with the MSK-IMPACT study reported at 3.30PM
- We identified that the mongo session service was down and had used up all disk space (20Gi) shortly

### Remediation

#### Bring mongodb back
- Take snapshot of existing EBS volume using AWS (no auto snapshots were set up)
- Set up new mongo database with helm:
    `helm install cbioportal-session-service-mongo-20230524 --version 7.3.1 --set image.tag=4.2,persistence.size=100Gi bitnami/mongodb`
- Connect the session service to use that one (see [commit](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment/commit/0042f9f1f0be26692032160fed82744d8f2a94dc))

#### Bring session data back
The mongo data was stored in an AWS snapshot in mongo's binary format, so not immediately accessible for re-import into another database. First we had to bring that back.

What didn't work:
- Tried various approach of expanding existing k8s volume, but was tricky b/c volume expansion wasn't enabled for existing PersistenceVolumeClaims

What did work:
- Instead, started a new AWS EC2 instance with that volume attached. For whatever reason i couldn’t see the attached volume within ubuntu at first (had to use [lsblk and mount](https://stackoverflow.com/questions/22816878/my-mounted-ebs-volume-is-not-showing-up)). Might be something you always have to do...
- Once the volume was accessible, we ran `docker run bitnami/mongodb` with the correct mount location specified to load the data
- From a separate shell used mongodump as described (cmds are described in cbioportal/README)
- Now that we got the dump, we set up a new mongo database in the k8s cluster to load the data:
    `helm install cbioportal-session-service-mongo-4dot2-20230525   --set image.tag=4.2,persistence.size=100Gi bitnami/mongodb`
- Then we had to copy over the data into that k8s volume. Unf `kubectl cp` didn't work (some TCP timeout error). Instead we figured we could create a 2nd container int he mongodb pod with rsync to copy over the data into a container in the existing k8s deployment:
    ```
    kubectl edit deployment cbioportal-session-service-mongo-4dot2-20230525-mongodb
    # add an ubuntu container
       - args:
         - infinity
         command:
         - sleep
         image: ubuntu
         imagePullPolicy: Always
         name: ubuntu
         resources: {}
         terminationMessagePath: /dev/termination-log
         terminationMessagePolicy: File
         volumeMounts:
         - mountPath: /bitnami/mongodb
           name: datadir
    # wait for it to be deployed
    kubectl exec -it cbioportal-session-service-mongo-4dot2-20230525-mongodb-f6wp9vx -c ubuntu -- /bin/sh
    # now you can apt-get install rsync, ssh, whatev into that container and rsync the mongo dump
    # then re-import the mongo database dump using instructions in cbioportal/README
