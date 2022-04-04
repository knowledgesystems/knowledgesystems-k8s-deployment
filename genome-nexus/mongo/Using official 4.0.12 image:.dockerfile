Using official 4.0.12 image:

(base) LSKI2813:~ lix2$ kubectl get  events --namespace=genome-nexus --field-selector involvedObject.name=gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0
LAST SEEN   FIRST SEEN   COUNT   NAME                                                                   KIND   SUBOBJECT                          TYPE      REASON                   SOURCE                                  MESSAGE
6m          6m           10      gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e1451e35903d7c   Pod                                       Warning   FailedScheduling         default-scheduler                       pod has unbound PersistentVolumeClaims (repeated 28 times)
6m          6m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e1451e72d04d5f   Pod                                       Normal    Scheduled                default-scheduler                       Successfully assigned genome-nexus/gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0 to ip-172-20-76-47.ec2.internal
6m          6m           2       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e1451e81c49bdf   Pod                                       Warning   FailedAttachVolume       attachdetach-controller                 AttachVolume.Attach failed for volume "pvc-89c9a944-b06e-11ec-a57d-124de1bb74c3" : "Error attaching EBS volume \"vol-07684c446e762a244\"" to instance "i-0cf7ae745c048db93" since volume is in "creating" state
6m          6m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e1451f5bd51f36   Pod                                       Normal    SuccessfulAttachVolume   attachdetach-controller                 AttachVolume.Attach succeeded for volume "pvc-89c9a944-b06e-11ec-a57d-124de1bb74c3"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e14522abe183ee   Pod    spec.containers{mongodb-primary}   Normal    Started                  kubelet, ip-172-20-76-47.ec2.internal   Started container
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e14522a0b30146   Pod    spec.containers{mongodb-primary}   Normal    Pulled                   kubelet, ip-172-20-76-47.ec2.internal   Successfully pulled image "docker.io/bitnami/mongodb:4.0.12"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e14522a4de174f   Pod    spec.containers{mongodb-primary}   Normal    Created                  kubelet, ip-172-20-76-47.ec2.internal   Created container
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e1452295e12dba   Pod    spec.containers{mongodb-primary}   Normal    Pulling                  kubelet, ip-172-20-76-47.ec2.internal   pulling image "docker.io/bitnami/mongodb:4.0.12"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e14522ac05cbd1   Pod    spec.containers{metrics}           Normal    Pulling                  kubelet, ip-172-20-76-47.ec2.internal   pulling image "docker.io/bitnami/mongodb-exporter:0.10.0-debian-9-r2"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e14522b264fba5   Pod    spec.containers{metrics}           Normal    Pulled                   kubelet, ip-172-20-76-47.ec2.internal   Successfully pulled image "docker.io/bitnami/mongodb-exporter:0.10.0-debian-9-r2"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e14522b6401f61   Pod    spec.containers{metrics}           Normal    Created                  kubelet, ip-172-20-76-47.ec2.internal   Created container
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e14522bc941597   Pod    spec.containers{metrics}           Normal    Started                  kubelet, ip-172-20-76-47.ec2.internal   Started container
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e145262fab8a04   Pod    spec.containers{mongodb-primary}   Warning   Unhealthy                kubelet, ip-172-20-76-47.ec2.internal   Readiness probe failed: MongoDB shell version v4.0.12
connecting to: mongodb://127.0.0.1:27017/?gssapiServiceName=mongodb
2022-03-30T21:16:08.898+0000 E QUERY    [js] Error: couldn't connect to server 127.0.0.1:27017, connection attempt failed: SocketException: Error connecting to 127.0.0.1:27017 :: caused by :: Connection refused :
connect@src/mongo/shell/mongo.js:344:17
@(connect):2:6
exception: connect failed

5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.16e1452782863851   Pod    spec.containers{metrics}           Warning   Unhealthy                kubelet, ip-172-20-76-47.ec2.internal   Readiness probe failed: Get http://100.96.52.99:9216/metrics: net/http: request canceled (Client.Timeout exceeded while awaiting headers)




(base) LSKI2813:~ lix2$ kubectl get  events --namespace=genome-nexus --field-selector involvedObject.name=gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0
LAST SEEN   FIRST SEEN   COUNT   NAME                                                                     KIND   SUBOBJECT                            TYPE      REASON                   SOURCE                                  MESSAGE
6m          6m           13      gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e1451e3caa8e25   Pod                                         Warning   FailedScheduling         default-scheduler                       pod has unbound PersistentVolumeClaims (repeated 28 times)
6m          6m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e1451f00bfc975   Pod                                         Normal    Scheduled                default-scheduler                       Successfully assigned genome-nexus/gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0 to ip-172-20-66-88.ec2.internal
6m          6m           2       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e1451f17c5923f   Pod                                         Warning   FailedAttachVolume       attachdetach-controller                 AttachVolume.Attach failed for volume "pvc-89d83abe-b06e-11ec-a57d-124de1bb74c3" : "Error attaching EBS volume \"vol-026baa932910687ec\"" to instance "i-00eb4e8f21d1dfd6a" since volume is in "creating" state
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e1452123de2931   Pod                                         Normal    SuccessfulAttachVolume   attachdetach-controller                 AttachVolume.Attach succeeded for volume "pvc-89d83abe-b06e-11ec-a57d-124de1bb74c3"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e145232a2565b2   Pod    spec.containers{mongodb-secondary}   Normal    Pulling                  kubelet, ip-172-20-66-88.ec2.internal   pulling image "docker.io/bitnami/mongodb:4.0.12"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e1452335e9cc33   Pod    spec.containers{mongodb-secondary}   Normal    Pulled                   kubelet, ip-172-20-66-88.ec2.internal   Successfully pulled image "docker.io/bitnami/mongodb:4.0.12"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e145233a05f4da   Pod    spec.containers{mongodb-secondary}   Normal    Created                  kubelet, ip-172-20-66-88.ec2.internal   Created container
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e145234cb5d8ee   Pod    spec.containers{mongodb-secondary}   Normal    Started                  kubelet, ip-172-20-66-88.ec2.internal   Started container
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e145234cf60a26   Pod    spec.containers{metrics}             Normal    Pulling                  kubelet, ip-172-20-66-88.ec2.internal   pulling image "docker.io/bitnami/mongodb-exporter:0.10.0-debian-9-r2"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e14523537b8130   Pod    spec.containers{metrics}             Normal    Pulled                   kubelet, ip-172-20-66-88.ec2.internal   Successfully pulled image "docker.io/bitnami/mongodb-exporter:0.10.0-debian-9-r2"
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e1452358c60a80   Pod    spec.containers{metrics}             Normal    Created                  kubelet, ip-172-20-66-88.ec2.internal   Created container
5m          5m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.16e14523680f877d   Pod    spec.containers{metrics}             Normal    Started                  kubelet, ip-172-20-66-88.ec2.internal   Started container




(base) LSKI2813:~ lix2$ kubectl get  events --namespace=genome-nexus --field-selector involvedObject.name=gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0
LAST SEEN   FIRST SEEN   COUNT   NAME                                                                   KIND   SUBOBJECT                          TYPE      REASON      SOURCE                                   MESSAGE
8m          8m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.16e1451e31ce62a2   Pod                                       Normal    Scheduled   default-scheduler                        Successfully assigned genome-nexus/gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0 to ip-172-20-83-132.ec2.internal
8m          8m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.16e1451e636ff080   Pod    spec.containers{mongodb-arbiter}   Normal    Pulled      kubelet, ip-172-20-83-132.ec2.internal   Container image "docker.io/bitnami/mongodb:4.0.12" already present on machine
8m          8m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.16e1451e67fbad77   Pod    spec.containers{mongodb-arbiter}   Normal    Created     kubelet, ip-172-20-83-132.ec2.internal   Created container
8m          8m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.16e1451e7279a089   Pod    spec.containers{mongodb-arbiter}   Normal    Started     kubelet, ip-172-20-83-132.ec2.internal   Started container
7m          7m           1       gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.16e1452e172d9a0c   Pod    spec.containers{mongodb-arbiter}   Warning   Unhealthy   kubelet, ip-172-20-83-132.ec2.internal   Liveness probe failed: dial tcp 100.96.83.172:27017: connect: connection refused




Logs from primary node: 

 21:15:53.82
 21:15:53.82 Welcome to the Bitnami mongodb container
 21:15:53.82 Subscribe to project updates by watching https://github.com/bitnami/bitnami-docker-mongodb
 21:15:53.82 Submit issues and feature requests at https://github.com/bitnami/bitnami-docker-mongodb/issues
 21:15:53.83 Send us your feedback at containers@bitnami.com
 21:15:53.83
 21:15:53.83 INFO  ==> ** Starting MongoDB setup **
 21:15:53.84 INFO  ==> Validating settings in MONGODB_* env vars...
 21:15:53.85 INFO  ==> Initializing MongoDB...
 21:15:53.86 INFO  ==> Deploying MongoDB from scratch...
 21:15:53.86 INFO  ==> No injected configuration files found. Creating default config files...
 21:15:54.75 INFO  ==> Creating users...
 21:15:54.76 INFO  ==> Creating root user...
 21:15:55.05 INFO  ==> Enabling authentication...
 21:15:55.06 INFO  ==> Users created
 21:15:55.06 INFO  ==> Writing keyfile for replica set authentication: dzkgNSopXm /opt/bitnami/mongodb/conf/keyfile
 21:15:55.07 INFO  ==> Configuring MongoDB replica set...
 21:15:55.08 INFO  ==> Stopping MongoDB...
 21:15:57.29 INFO  ==> Configuring MongoDB primary node...: gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local
 21:15:57.54 INFO  ==> Stopping MongoDB...
 21:16:12.58 INFO  ==>
 21:16:12.58 INFO  ==> ########################################################################
 21:16:12.58 INFO  ==>  Installation parameters for MongoDB:
 21:16:12.59 INFO  ==>   Root Password: **********
 21:16:12.59 INFO  ==>   Replication Mode: primary
 21:16:12.59 INFO  ==> (Passwords are not shown for security reasons)
 21:16:12.59 INFO  ==> ########################################################################
 21:16:12.59 INFO  ==>
 21:16:12.59 INFO  ==> Loading custom scripts...
find: '/docker-entrypoint-initdb.d/': No such file or directory
 21:16:12.60 INFO  ==> ** MongoDB setup finished! **

 21:16:12.62 INFO  ==> ** Starting MongoDB **
2022-03-30T21:16:12.641+0000 I STORAGE  [main] Max cache overflow file size custom option: 0
2022-03-30T21:16:12.641+0000 I CONTROL  [main] ***** SERVER RESTARTED *****
2022-03-30T21:16:12.644+0000 I CONTROL  [main] Automatically disabling TLS 1.0, to force-enable TLS 1.0 specify --sslDisabledProtocols 'none'
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten] MongoDB starting : pid=1 port=27017 dbpath=/bitnami/mongodb/data/db 64-bit host=gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten] db version v4.0.12
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten] git version: 5776e3cbf9e7afe86e6b29e22520ffb6766e95d4
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten] OpenSSL version: OpenSSL 1.1.0l  10 Sep 2019
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten] allocator: tcmalloc
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten] modules: none
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten] build environment:
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten]     distmod: debian92
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten]     distarch: x86_64
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten]     target_arch: x86_64
2022-03-30T21:16:12.662+0000 I CONTROL  [initandlisten] options: { config: "/opt/bitnami/mongodb/conf/mongodb.conf", net: { bindIpAll: true, ipv6: false, port: 27017, unixDomainSocket: { enabled: true, pathPrefix: "/opt/bitnami/mongodb/tmp" } }, processManagement: { fork: false, pidFilePath: "/opt/bitnami/mongodb/tmp/mongodb.pid" }, replication: { enableMajorityReadConcern: true, replSetName: "rs012" }, security: { authorization: "enabled", keyFile: "/opt/bitnami/mongodb/conf/keyfile" }, setParameter: { enableLocalhostAuthBypass: "false" }, storage: { dbPath: "/bitnami/mongodb/data/db", directoryPerDB: false, journal: { enabled: true } }, systemLog: { destination: "file", logAppend: true, logRotate: "reopen", path: "/opt/bitnami/mongodb/logs/mongodb.log", quiet: false, verbosity: 0 } }
2022-03-30T21:16:12.662+0000 I STORAGE  [initandlisten] Detected data files in /bitnami/mongodb/data/db created by the 'wiredTiger' storage engine, so setting the active storage engine to 'wiredTiger'.
2022-03-30T21:16:12.662+0000 I STORAGE  [initandlisten]
2022-03-30T21:16:12.662+0000 I STORAGE  [initandlisten] ** WARNING: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine
2022-03-30T21:16:12.662+0000 I STORAGE  [initandlisten] **          See http://dochub.mongodb.org/core/prodnotes-filesystem
2022-03-30T21:16:12.662+0000 I STORAGE  [initandlisten] wiredtiger_open config: create,cache_size=7420M,cache_overflow=(file_max=0M),session_max=20000,eviction=(threads_min=4,threads_max=4),config_base=false,statistics=(fast),log=(enabled=true,archive=true,path=journal,compressor=snappy),file_manager=(close_idle_time=100000),statistics_log=(wait=0),verbose=(recovery_progress),
2022-03-30T21:16:13.665+0000 I STORAGE  [initandlisten] WiredTiger message [1648674973:665115][1:0x7f9f59865080], txn-recover: Main recovery loop: starting at 2/38784 to 3/256
2022-03-30T21:16:13.665+0000 I STORAGE  [initandlisten] WiredTiger message [1648674973:665503][1:0x7f9f59865080], txn-recover: Recovering log 2 through 3
2022-03-30T21:16:14.062+0000 I STORAGE  [initandlisten] WiredTiger message [1648674974:62966][1:0x7f9f59865080], txn-recover: Recovering log 3 through 3
2022-03-30T21:16:14.125+0000 I STORAGE  [initandlisten] WiredTiger message [1648674974:125937][1:0x7f9f59865080], txn-recover: Set global recovery timestamp: 6244c88f00000002
2022-03-30T21:16:14.138+0000 I RECOVERY [initandlisten] WiredTiger recoveryTimestamp. Ts: Timestamp(1648674959, 2)
2022-03-30T21:16:14.138+0000 I STORAGE  [initandlisten] Triggering the first stable checkpoint. Initial Data: Timestamp(1648674959, 2) PrevStable: Timestamp(0, 0) CurrStable: Timestamp(1648674959, 2)
2022-03-30T21:16:14.146+0000 I STORAGE  [initandlisten] Starting OplogTruncaterThread local.oplog.rs
2022-03-30T21:16:14.147+0000 I STORAGE  [initandlisten] The size storer reports that the oplog contains 3 records totaling to 439 bytes
2022-03-30T21:16:14.147+0000 I STORAGE  [initandlisten] Scanning the oplog to determine where to place markers for truncation
2022-03-30T21:16:14.194+0000 I FTDC     [initandlisten] Initializing full-time diagnostic data capture with directory '/bitnami/mongodb/data/db/diagnostic.data'
2022-03-30T21:16:14.198+0000 I REPL     [initandlisten] Rollback ID is 1
2022-03-30T21:16:14.198+0000 I REPL     [initandlisten] Recovering from stable timestamp: Timestamp(1648674959, 2) (top of oplog: { ts: Timestamp(1648674959, 2), t: 1 }, appliedThrough: { ts: Timestamp(0, 0), t: -1 }, TruncateAfter: Timestamp(0, 0))
2022-03-30T21:16:14.198+0000 I REPL     [initandlisten] Starting recovery oplog application at the stable timestamp: Timestamp(1648674959, 2)
2022-03-30T21:16:14.198+0000 I REPL     [initandlisten] No oplog entries to apply for recovery. Start point is at the top of the oplog.
2022-03-30T21:16:14.199+0000 I REPL     [replexec-0] New replica set config in use: { _id: "rs012", version: 1, protocolVersion: 1, writeConcernMajorityJournalDefault: true, members: [ { _id: 0, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: false, buildIndexes: true, hidden: false, priority: 5.0, tags: {}, slaveDelay: 0, votes: 1 } ], settings: { chainingAllowed: true, heartbeatIntervalMillis: 2000, heartbeatTimeoutSecs: 10, electionTimeoutMillis: 10000, catchUpTimeoutMillis: -1, catchUpTakeoverDelayMillis: 30000, getLastErrorModes: {}, getLastErrorDefaults: { w: 1, wtimeout: 0 }, replicaSetId: ObjectId('6244c88d2f2a1e6520904cea') } }
2022-03-30T21:16:14.199+0000 I REPL     [replexec-0] This node is gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 in the config
2022-03-30T21:16:14.199+0000 I REPL     [replexec-0] transition to STARTUP2 from STARTUP
2022-03-30T21:16:14.199+0000 I REPL     [replexec-0] Starting replication storage threads
2022-03-30T21:16:14.199+0000 I NETWORK  [LogicalSessionCacheRefresh] Starting new replica set monitor for rs012/gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:16:14.200+0000 I NETWORK  [initandlisten] waiting for connections on port 27017
2022-03-30T21:16:14.200+0000 I NETWORK  [listener] connection accepted from 100.96.52.99:55352 #2 (1 connection now open)
2022-03-30T21:16:14.200+0000 I NETWORK  [conn2] received client metadata from 100.96.52.99:55352 conn2: { driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:14.200+0000 I REPL     [replexec-0] transition to RECOVERING from STARTUP2
2022-03-30T21:16:14.200+0000 I REPL     [replexec-0] Starting replication fetcher thread
2022-03-30T21:16:14.200+0000 I REPL     [replexec-0] Starting replication applier thread
2022-03-30T21:16:14.200+0000 I NETWORK  [LogicalSessionCacheRefresh] Successfully connected to gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (1 connections now open to gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 with a 5 second timeout)
2022-03-30T21:16:14.201+0000 I REPL     [rsSync-0] Starting oplog application
2022-03-30T21:16:14.201+0000 I REPL     [replexec-0] Starting replication reporter thread
2022-03-30T21:16:14.201+0000 I REPL     [rsSync-0] transition to SECONDARY from RECOVERING
2022-03-30T21:16:14.201+0000 I REPL     [rsSync-0] conducting a dry run election to see if we could be elected. current term: 1
2022-03-30T21:16:14.201+0000 W NETWORK  [LogicalSessionCacheRefresh] Unable to reach primary for set rs012
2022-03-30T21:16:14.201+0000 I REPL     [replexec-0] dry election run succeeded, running for election in term 2
2022-03-30T21:16:14.202+0000 I REPL     [replexec-0] election succeeded, assuming primary role in term 2
2022-03-30T21:16:14.202+0000 I REPL     [replexec-0] transition to PRIMARY from SECONDARY
2022-03-30T21:16:14.202+0000 I REPL     [replexec-0] Resetting sync source to empty, which was :27017
2022-03-30T21:16:14.202+0000 I REPL     [replexec-0] Entering primary catch-up mode.
2022-03-30T21:16:14.202+0000 I REPL     [replexec-0] Exited primary catch-up mode.
2022-03-30T21:16:14.202+0000 I REPL     [replexec-0] Stopping replication producer
2022-03-30T21:16:14.593+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:36276 #3 (2 connections now open)
2022-03-30T21:16:14.593+0000 I NETWORK  [conn3] received client metadata from 127.0.0.1:36276 conn3: { driver: { name: "mongo-go-driver", version: "v1.1.1" }, os: { type: "linux", architecture: "amd64" }, platform: "go1.12.9" }
2022-03-30T21:16:14.594+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:36280 #4 (3 connections now open)
2022-03-30T21:16:14.594+0000 I NETWORK  [conn4] received client metadata from 127.0.0.1:36280 conn4: { driver: { name: "mongo-go-driver", version: "v1.1.1" }, os: { type: "linux", architecture: "amd64" }, platform: "go1.12.9", application: { name: "mongodb_exporter" } }
2022-03-30T21:16:14.623+0000 I ACCESS   [conn4] Successfully authenticated as principal root on admin from client 127.0.0.1:36280
2022-03-30T21:16:14.701+0000 W NETWORK  [LogicalSessionCacheRefresh] Unable to reach primary for set rs012
2022-03-30T21:16:15.202+0000 W NETWORK  [LogicalSessionCacheRefresh] Unable to reach primary for set rs012
2022-03-30T21:16:15.702+0000 W NETWORK  [LogicalSessionCacheRefresh] Unable to reach primary for set rs012
2022-03-30T21:16:16.202+0000 I REPL     [rsSync-0] transition to primary complete; database writes are now permitted
2022-03-30T21:16:16.202+0000 I STORAGE  [monitoring keys for HMAC] createCollection: admin.system.keys with generated UUID: 8f359070-708e-41fc-b543-766d5afa27c9
2022-03-30T21:16:16.203+0000 I NETWORK  [listener] connection accepted from 100.96.52.99:56324 #6 (4 connections now open)
2022-03-30T21:16:16.203+0000 I NETWORK  [conn6] received client metadata from 100.96.52.99:56324 conn6: { driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:16.203+0000 I NETWORK  [LogicalSessionCacheRefresh] Successfully connected to gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (1 connections now open to gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 with a 0 second timeout)
2022-03-30T21:16:16.217+0000 I ACCESS   [conn6] Successfully authenticated as principal __system on local from client 100.96.52.99:56324
2022-03-30T21:16:18.879+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:38208 #7 (5 connections now open)
2022-03-30T21:16:18.879+0000 I NETWORK  [conn7] received client metadata from 127.0.0.1:38208 conn7: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:18.883+0000 I NETWORK  [conn7] end connection 127.0.0.1:38208 (4 connections now open)
2022-03-30T21:16:28.917+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:43058 #8 (5 connections now open)
2022-03-30T21:16:28.918+0000 I NETWORK  [conn8] received client metadata from 127.0.0.1:43058 conn8: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:28.923+0000 I NETWORK  [conn8] end connection 127.0.0.1:43058 (4 connections now open)
2022-03-30T21:16:38.871+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:47900 #9 (5 connections now open)
2022-03-30T21:16:38.871+0000 I NETWORK  [conn9] received client metadata from 127.0.0.1:47900 conn9: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:38.877+0000 I NETWORK  [conn9] end connection 127.0.0.1:47900 (4 connections now open)
2022-03-30T21:16:39.846+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:58600 #10 (5 connections now open)
2022-03-30T21:16:39.847+0000 I NETWORK  [conn10] end connection 100.96.83.172:58600 (4 connections now open)
2022-03-30T21:16:39.924+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:58602 #11 (5 connections now open)
2022-03-30T21:16:39.925+0000 I NETWORK  [conn11] received client metadata from 100.96.83.172:58602 conn11: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:39.968+0000 I ACCESS   [conn11] Successfully authenticated as principal root on admin from client 100.96.83.172:58602
2022-03-30T21:16:39.985+0000 I NETWORK  [conn11] end connection 100.96.83.172:58602 (4 connections now open)
2022-03-30T21:16:40.081+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:58604 #12 (5 connections now open)
2022-03-30T21:16:40.082+0000 I NETWORK  [conn12] received client metadata from 100.96.83.172:58604 conn12: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:40.143+0000 I ACCESS   [conn12] Successfully authenticated as principal root on admin from client 100.96.83.172:58604
2022-03-30T21:16:40.153+0000 I NETWORK  [conn12] end connection 100.96.83.172:58604 (4 connections now open)
2022-03-30T21:16:40.238+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:58606 #13 (5 connections now open)
2022-03-30T21:16:40.238+0000 I NETWORK  [conn13] received client metadata from 100.96.83.172:58606 conn13: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:40.274+0000 I ACCESS   [conn13] Successfully authenticated as principal root on admin from client 100.96.83.172:58606
2022-03-30T21:16:40.283+0000 I NETWORK  [conn13] end connection 100.96.83.172:58606 (4 connections now open)
2022-03-30T21:16:40.377+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:58608 #14 (5 connections now open)
2022-03-30T21:16:40.377+0000 I NETWORK  [conn14] received client metadata from 100.96.83.172:58608 conn14: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:40.409+0000 I ACCESS   [conn14] Successfully authenticated as principal root on admin from client 100.96.83.172:58608
2022-03-30T21:16:40.425+0000 I REPL     [conn14] replSetReconfig admin command received from client; new config: { _id: "rs012", version: 2, protocolVersion: 1, writeConcernMajorityJournalDefault: true, members: [ { _id: 0, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: false, buildIndexes: true, hidden: false, priority: 5.0, tags: {}, slaveDelay: 0, votes: 1 }, { _id: 1.0, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: true } ], settings: { chainingAllowed: true, heartbeatIntervalMillis: 2000, heartbeatTimeoutSecs: 10, electionTimeoutMillis: 10000, catchUpTimeoutMillis: -1, catchUpTakeoverDelayMillis: 30000, getLastErrorModes: {}, getLastErrorDefaults: { w: 1, wtimeout: 0 }, replicaSetId: ObjectId('6244c88d2f2a1e6520904cea') } }
2022-03-30T21:16:40.446+0000 I REPL     [conn14] replSetReconfig config object with 2 members parses ok
2022-03-30T21:16:40.446+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:16:40.452+0000 I REPL     [replexec-1] New replica set config in use: { _id: "rs012", version: 2, protocolVersion: 1, writeConcernMajorityJournalDefault: true, members: [ { _id: 0, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: false, buildIndexes: true, hidden: false, priority: 5.0, tags: {}, slaveDelay: 0, votes: 1 }, { _id: 1, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: true, buildIndexes: true, hidden: false, priority: 0.0, tags: {}, slaveDelay: 0, votes: 1 } ], settings: { chainingAllowed: true, heartbeatIntervalMillis: 2000, heartbeatTimeoutSecs: 10, electionTimeoutMillis: 10000, catchUpTimeoutMillis: -1, catchUpTakeoverDelayMillis: 30000, getLastErrorModes: {}, getLastErrorDefaults: { w: 1, wtimeout: 0 }, replicaSetId: ObjectId('6244c88d2f2a1e6520904cea') } }
2022-03-30T21:16:40.452+0000 I REPL     [replexec-1] This node is gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 in the config
2022-03-30T21:16:40.452+0000 I REPL     [replexec-2] Member gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 is now in state STARTUP
2022-03-30T21:16:40.456+0000 I NETWORK  [conn14] end connection 100.96.83.172:58608 (4 connections now open)
2022-03-30T21:16:40.457+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:52228 #17 (5 connections now open)
2022-03-30T21:16:40.457+0000 I NETWORK  [conn17] received client metadata from 100.96.83.172:52228 conn17: { driver: { name: "NetworkInterfaceTL", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:40.479+0000 I ACCESS   [conn17] Successfully authenticated as principal __system on local from client 100.96.83.172:52228
2022-03-30T21:16:40.482+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:52230 #18 (6 connections now open)
2022-03-30T21:16:40.484+0000 I ACCESS   [conn18] Successfully authenticated as principal __system on local from client 100.96.83.172:52230
2022-03-30T21:16:40.486+0000 I NETWORK  [conn18] end connection 100.96.83.172:52230 (5 connections now open)
2022-03-30T21:16:40.541+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:58614 #19 (6 connections now open)
2022-03-30T21:16:40.541+0000 I NETWORK  [conn19] received client metadata from 100.96.83.172:58614 conn19: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:40.580+0000 I ACCESS   [conn19] Successfully authenticated as principal root on admin from client 100.96.83.172:58614
2022-03-30T21:16:40.590+0000 I NETWORK  [conn19] end connection 100.96.83.172:58614 (5 connections now open)
2022-03-30T21:16:40.611+0000 I NETWORK  [conn17] end connection 100.96.83.172:52228 (4 connections now open)
2022-03-30T21:16:42.452+0000 I CONNPOOL [Replication] dropping unhealthy pooled connection to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:16:42.452+0000 I CONNPOOL [Replication] after drop, pool was empty, going to spawn some connections
2022-03-30T21:16:42.452+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:16:42.453+0000 I ASIO     [Replication] Failed to connect to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 - HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.83.172:27017) :: caused by :: Connection refused
2022-03-30T21:16:42.453+0000 I CONNPOOL [Replication] Dropping all pooled connections to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 due to HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.83.172:27017) :: caused by :: Connection refused
2022-03-30T21:16:42.453+0000 I REPL_HB  [replexec-0] Error in heartbeat (requestId: 12) to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017, response status: HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.83.172:27017) :: caused by :: Connection refused
2022-03-30T21:16:42.453+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:16:42.454+0000 I ASIO     [Replication] Failed to connect to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 - HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.83.172:27017) :: caused by :: Connection refused
2022-03-30T21:16:42.454+0000 I CONNPOOL [Replication] Dropping all pooled connections to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 due to HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.83.172:27017) :: caused by :: Connection refused
2022-03-30T21:16:42.454+0000 I REPL_HB  [replexec-1] Error in heartbeat (requestId: 13) to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017, response status: HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.83.172:27017) :: caused by :: Connection refused
2022-03-30T21:16:42.455+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:16:42.457+0000 I ASIO     [Replication] Failed to connect to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 - HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.83.172:27017) :: caused by :: Connection refused
2022-03-30T21:16:42.457+0000 I CONNPOOL [Replication] Dropping all pooled connections to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 due to HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.83.172:27017) :: caused by :: Connection refused
2022-03-30T21:16:42.457+0000 I REPL_HB  [replexec-0] Error in heartbeat (requestId: 14) to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017, response status: HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.83.172:27017) :: caused by :: Connection refused
2022-03-30T21:16:42.457+0000 I REPL     [replexec-0] Member gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 is now in state RS_DOWN
2022-03-30T21:16:43.498+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:52244 #20 (5 connections now open)
2022-03-30T21:16:43.515+0000 I ACCESS   [conn20] Successfully authenticated as principal __system on local from client 100.96.83.172:52244
2022-03-30T21:16:43.516+0000 I NETWORK  [conn20] end connection 100.96.83.172:52244 (4 connections now open)
2022-03-30T21:16:43.518+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:52246 #21 (5 connections now open)
2022-03-30T21:16:43.518+0000 I NETWORK  [conn21] received client metadata from 100.96.83.172:52246 conn21: { driver: { name: "NetworkInterfaceTL", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:43.519+0000 I ACCESS   [conn21] Successfully authenticated as principal __system on local from client 100.96.83.172:52246
2022-03-30T21:16:44.457+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:16:44.498+0000 I REPL     [replexec-0] Member gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 is now in state ARBITER
2022-03-30T21:16:48.868+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:52808 #23 (6 connections now open)
2022-03-30T21:16:48.869+0000 I NETWORK  [conn23] received client metadata from 127.0.0.1:52808 conn23: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:48.877+0000 I NETWORK  [conn23] end connection 127.0.0.1:52808 (5 connections now open)
2022-03-30T21:16:58.895+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:57754 #24 (6 connections now open)
2022-03-30T21:16:58.896+0000 I NETWORK  [conn24] received client metadata from 127.0.0.1:57754 conn24: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:16:58.903+0000 I NETWORK  [conn24] end connection 127.0.0.1:57754 (5 connections now open)
2022-03-30T21:17:00.661+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:35108 #25 (6 connections now open)
2022-03-30T21:17:00.662+0000 I NETWORK  [conn25] end connection 100.96.78.144:35108 (5 connections now open)
2022-03-30T21:17:00.735+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:35110 #26 (6 connections now open)
2022-03-30T21:17:00.744+0000 I NETWORK  [conn26] received client metadata from 100.96.78.144:35110 conn26: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:00.791+0000 I ACCESS   [conn26] Successfully authenticated as principal root on admin from client 100.96.78.144:35110
2022-03-30T21:17:00.810+0000 I NETWORK  [conn26] end connection 100.96.78.144:35110 (5 connections now open)
2022-03-30T21:17:00.880+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:35112 #27 (6 connections now open)
2022-03-30T21:17:00.881+0000 I NETWORK  [conn27] received client metadata from 100.96.78.144:35112 conn27: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:00.909+0000 I ACCESS   [conn27] Successfully authenticated as principal root on admin from client 100.96.78.144:35112
2022-03-30T21:17:00.917+0000 I NETWORK  [conn27] end connection 100.96.78.144:35112 (5 connections now open)
2022-03-30T21:17:00.981+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:35114 #28 (6 connections now open)
2022-03-30T21:17:00.982+0000 I NETWORK  [conn28] received client metadata from 100.96.78.144:35114 conn28: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:01.010+0000 I ACCESS   [conn28] Successfully authenticated as principal root on admin from client 100.96.78.144:35114
2022-03-30T21:17:01.027+0000 I NETWORK  [conn28] end connection 100.96.78.144:35114 (5 connections now open)
2022-03-30T21:17:01.092+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:35118 #29 (6 connections now open)
2022-03-30T21:17:01.092+0000 I NETWORK  [conn29] received client metadata from 100.96.78.144:35118 conn29: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:01.123+0000 I ACCESS   [conn29] Successfully authenticated as principal root on admin from client 100.96.78.144:35118
2022-03-30T21:17:01.135+0000 I REPL     [conn29] replSetReconfig admin command received from client; new config: { _id: "rs012", version: 3, protocolVersion: 1, writeConcernMajorityJournalDefault: true, members: [ { _id: 0, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: false, buildIndexes: true, hidden: false, priority: 5.0, tags: {}, slaveDelay: 0, votes: 1 }, { _id: 1, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: true, buildIndexes: true, hidden: false, priority: 0.0, tags: {}, slaveDelay: 0, votes: 1 }, { _id: 2.0, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017" } ], settings: { chainingAllowed: true, heartbeatIntervalMillis: 2000, heartbeatTimeoutSecs: 10, electionTimeoutMillis: 10000, catchUpTimeoutMillis: -1, catchUpTakeoverDelayMillis: 30000, getLastErrorModes: {}, getLastErrorDefaults: { w: 1, wtimeout: 0 }, replicaSetId: ObjectId('6244c88d2f2a1e6520904cea') } }
2022-03-30T21:17:01.162+0000 I REPL     [conn29] replSetReconfig config object with 3 members parses ok
2022-03-30T21:17:01.162+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:17:01.164+0000 I REPL     [replexec-0] New replica set config in use: { _id: "rs012", version: 3, protocolVersion: 1, writeConcernMajorityJournalDefault: true, members: [ { _id: 0, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: false, buildIndexes: true, hidden: false, priority: 5.0, tags: {}, slaveDelay: 0, votes: 1 }, { _id: 1, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-arbiter-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: true, buildIndexes: true, hidden: false, priority: 0.0, tags: {}, slaveDelay: 0, votes: 1 }, { _id: 2, host: "gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017", arbiterOnly: false, buildIndexes: true, hidden: false, priority: 1.0, tags: {}, slaveDelay: 0, votes: 1 } ], settings: { chainingAllowed: true, heartbeatIntervalMillis: 2000, heartbeatTimeoutSecs: 10, electionTimeoutMillis: 10000, catchUpTimeoutMillis: -1, catchUpTakeoverDelayMillis: 30000, getLastErrorModes: {}, getLastErrorDefaults: { w: 1, wtimeout: 0 }, replicaSetId: ObjectId('6244c88d2f2a1e6520904cea') } }
2022-03-30T21:17:01.164+0000 I REPL     [replexec-0] This node is gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 in the config
2022-03-30T21:17:01.164+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:17:01.167+0000 I CONNPOOL [Replication] Ending idle connection to host gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 because the pool meets constraints; 1 connections to that host remain open
2022-03-30T21:17:01.169+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:52322 #34 (7 connections now open)
2022-03-30T21:17:01.170+0000 I ACCESS   [conn34] Successfully authenticated as principal __system on local from client 100.96.83.172:52322
2022-03-30T21:17:01.171+0000 I NETWORK  [conn34] end connection 100.96.83.172:52322 (6 connections now open)
2022-03-30T21:17:01.172+0000 I NETWORK  [conn29] end connection 100.96.78.144:35118 (5 connections now open)
2022-03-30T21:17:01.173+0000 I REPL     [replexec-1] Member gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 is now in state STARTUP
2022-03-30T21:17:01.175+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:45162 #35 (6 connections now open)
2022-03-30T21:17:01.175+0000 I NETWORK  [conn35] received client metadata from 100.96.78.144:45162 conn35: { driver: { name: "NetworkInterfaceTL", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:01.190+0000 I ACCESS   [conn35] Successfully authenticated as principal __system on local from client 100.96.78.144:45162
2022-03-30T21:17:01.202+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:45164 #36 (7 connections now open)
2022-03-30T21:17:01.205+0000 I ACCESS   [conn36] Successfully authenticated as principal __system on local from client 100.96.78.144:45164
2022-03-30T21:17:01.206+0000 I NETWORK  [conn36] end connection 100.96.78.144:45164 (6 connections now open)
2022-03-30T21:17:01.240+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:35128 #37 (7 connections now open)
2022-03-30T21:17:01.241+0000 I NETWORK  [conn37] received client metadata from 100.96.78.144:35128 conn37: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:01.273+0000 I ACCESS   [conn37] Successfully authenticated as principal root on admin from client 100.96.78.144:35128
2022-03-30T21:17:01.286+0000 I NETWORK  [conn37] end connection 100.96.78.144:35128 (6 connections now open)
2022-03-30T21:17:01.375+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:35132 #38 (7 connections now open)
2022-03-30T21:17:01.375+0000 I NETWORK  [conn38] received client metadata from 100.96.78.144:35132 conn38: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:01.388+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:45176 #39 (8 connections now open)
2022-03-30T21:17:01.389+0000 I NETWORK  [conn39] received client metadata from 100.96.78.144:45176 conn39: { driver: { name: "NetworkInterfaceTL", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:01.391+0000 I ACCESS   [conn39] Successfully authenticated as principal __system on local from client 100.96.78.144:45176
2022-03-30T21:17:01.399+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:45178 #40 (9 connections now open)
2022-03-30T21:17:01.399+0000 I NETWORK  [conn40] received client metadata from 100.96.78.144:45178 conn40: { driver: { name: "NetworkInterfaceTL", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:01.404+0000 I ACCESS   [conn40] Successfully authenticated as principal __system on local from client 100.96.78.144:45178
2022-03-30T21:17:01.405+0000 I ACCESS   [conn38] Successfully authenticated as principal root on admin from client 100.96.78.144:35132
2022-03-30T21:17:01.428+0000 I NETWORK  [conn38] end connection 100.96.78.144:35132 (8 connections now open)
2022-03-30T21:17:02.496+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:35142 #41 (9 connections now open)
2022-03-30T21:17:02.496+0000 I NETWORK  [conn41] received client metadata from 100.96.78.144:35142 conn41: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:02.525+0000 I ACCESS   [conn41] Successfully authenticated as principal root on admin from client 100.96.78.144:35142
2022-03-30T21:17:02.537+0000 I NETWORK  [conn41] end connection 100.96.78.144:35142 (8 connections now open)
2022-03-30T21:17:03.174+0000 I REPL     [replexec-1] Member gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 is now in state SECONDARY
2022-03-30T21:17:03.600+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:35150 #42 (9 connections now open)
2022-03-30T21:17:03.600+0000 I NETWORK  [conn42] received client metadata from 100.96.78.144:35150 conn42: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:03.629+0000 I ACCESS   [conn42] Successfully authenticated as principal root on admin from client 100.96.78.144:35150
2022-03-30T21:17:03.641+0000 I NETWORK  [conn42] end connection 100.96.78.144:35150 (8 connections now open)
2022-03-30T21:17:04.598+0000 I NETWORK  [conn40] end connection 100.96.78.144:45178 (7 connections now open)
2022-03-30T21:17:04.599+0000 I NETWORK  [conn35] end connection 100.96.78.144:45162 (6 connections now open)
2022-03-30T21:17:05.174+0000 I CONNPOOL [Replication] dropping unhealthy pooled connection to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:17:05.174+0000 I CONNPOOL [Replication] after drop, pool was empty, going to spawn some connections
2022-03-30T21:17:05.174+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:17:05.175+0000 I ASIO     [Replication] Failed to connect to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 - HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.78.144:27017) :: caused by :: Connection refused
2022-03-30T21:17:05.175+0000 I CONNPOOL [Replication] Dropping all pooled connections to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 due to HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.78.144:27017) :: caused by :: Connection refused
2022-03-30T21:17:05.176+0000 I REPL_HB  [replexec-1] Error in heartbeat (requestId: 46) to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017, response status: HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.78.144:27017) :: caused by :: Connection refused
2022-03-30T21:17:05.176+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:17:05.177+0000 I ASIO     [Replication] Failed to connect to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 - HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.78.144:27017) :: caused by :: Connection refused
2022-03-30T21:17:05.177+0000 I CONNPOOL [Replication] Dropping all pooled connections to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 due to HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.78.144:27017) :: caused by :: Connection refused
2022-03-30T21:17:05.177+0000 I REPL_HB  [replexec-0] Error in heartbeat (requestId: 47) to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017, response status: HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.78.144:27017) :: caused by :: Connection refused
2022-03-30T21:17:05.178+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:17:05.179+0000 I ASIO     [Replication] Failed to connect to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 - HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.78.144:27017) :: caused by :: Connection refused
2022-03-30T21:17:05.179+0000 I CONNPOOL [Replication] Dropping all pooled connections to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 due to HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.78.144:27017) :: caused by :: Connection refused
2022-03-30T21:17:05.179+0000 I REPL_HB  [replexec-1] Error in heartbeat (requestId: 48) to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017, response status: HostUnreachable: Error connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 (100.96.78.144:27017) :: caused by :: Connection refused
2022-03-30T21:17:05.179+0000 I REPL     [replexec-1] Member gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 is now in state RS_DOWN
2022-03-30T21:17:06.399+0000 I NETWORK  [conn39] end connection 100.96.78.144:45176 (5 connections now open)
2022-03-30T21:17:07.005+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:45226 #43 (6 connections now open)
2022-03-30T21:17:07.019+0000 I ACCESS   [conn43] Successfully authenticated as principal __system on local from client 100.96.78.144:45226
2022-03-30T21:17:07.019+0000 I NETWORK  [conn43] end connection 100.96.78.144:45226 (5 connections now open)
2022-03-30T21:17:07.042+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:45232 #44 (6 connections now open)
2022-03-30T21:17:07.042+0000 I NETWORK  [conn44] received client metadata from 100.96.78.144:45232 conn44: { driver: { name: "NetworkInterfaceTL", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:07.044+0000 I ACCESS   [conn44] Successfully authenticated as principal __system on local from client 100.96.78.144:45232
2022-03-30T21:17:07.179+0000 I ASIO     [Replication] Connecting to gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017
2022-03-30T21:17:07.203+0000 I REPL     [replexec-1] Member gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0.gn-mongo-v0dot23-grch38-ensembl95-mongodb-headless.genome-nexus.svc.cluster.local:27017 is now in state SECONDARY
2022-03-30T21:17:08.898+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:36878 #46 (7 connections now open)
2022-03-30T21:17:08.898+0000 I NETWORK  [conn46] received client metadata from 127.0.0.1:36878 conn46: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:17:08.902+0000 I NETWORK  [conn46] end connection 127.0.0.1:36878 (6 connections now open)
2022-03-30T21:17:17.045+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:45288 #47 (7 connections now open)
2022-03-30T21:17:17.046+0000 I NETWORK  [conn47] received client metadata from 100.96.78.144:45288 conn47: { driver: { name: "NetworkInterfaceTL", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:17.048+0000 I ACCESS   [conn47] Successfully authenticated as principal __system on local from client 100.96.78.144:45288
2022-03-30T21:17:17.053+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:45290 #48 (8 connections now open)
2022-03-30T21:17:17.065+0000 I NETWORK  [conn48] received client metadata from 100.96.78.144:45290 conn48: { driver: { name: "NetworkInterfaceTL", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:17:17.075+0000 I ACCESS   [conn48] Successfully authenticated as principal __system on local from client 100.96.78.144:45290
2022-03-30T21:17:18.887+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:41968 #49 (9 connections now open)
2022-03-30T21:17:18.888+0000 I NETWORK  [conn49] received client metadata from 127.0.0.1:41968 conn49: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:17:18.892+0000 I NETWORK  [conn49] end connection 127.0.0.1:41968 (8 connections now open)
2022-03-30T21:17:28.902+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:46800 #50 (9 connections now open)
2022-03-30T21:17:28.903+0000 I NETWORK  [conn50] received client metadata from 127.0.0.1:46800 conn50: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:17:28.908+0000 I NETWORK  [conn50] end connection 127.0.0.1:46800 (8 connections now open)
2022-03-30T21:17:38.898+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:51644 #51 (9 connections now open)
2022-03-30T21:17:38.898+0000 I NETWORK  [conn51] received client metadata from 127.0.0.1:51644 conn51: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:17:38.903+0000 I NETWORK  [conn51] end connection 127.0.0.1:51644 (8 connections now open)
2022-03-30T21:17:48.916+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:56566 #52 (9 connections now open)
2022-03-30T21:17:48.916+0000 I NETWORK  [conn52] received client metadata from 127.0.0.1:56566 conn52: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:17:48.933+0000 I NETWORK  [conn52] end connection 127.0.0.1:56566 (8 connections now open)
2022-03-30T21:17:58.926+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:33252 #53 (9 connections now open)
2022-03-30T21:17:58.926+0000 I NETWORK  [conn53] received client metadata from 127.0.0.1:33252 conn53: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:17:58.930+0000 I NETWORK  [conn53] end connection 127.0.0.1:33252 (8 connections now open)
2022-03-30T21:18:08.909+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:37718 #54 (9 connections now open)
2022-03-30T21:18:08.910+0000 I NETWORK  [conn54] received client metadata from 127.0.0.1:37718 conn54: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:18:08.916+0000 I NETWORK  [conn54] end connection 127.0.0.1:37718 (8 connections now open)
2022-03-30T21:18:18.894+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:42438 #55 (9 connections now open)
2022-03-30T21:18:18.894+0000 I NETWORK  [conn55] received client metadata from 127.0.0.1:42438 conn55: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:18:18.900+0000 I NETWORK  [conn55] end connection 127.0.0.1:42438 (8 connections now open)
2022-03-30T21:18:28.909+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:47300 #56 (9 connections now open)
2022-03-30T21:18:28.909+0000 I NETWORK  [conn56] received client metadata from 127.0.0.1:47300 conn56: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:18:28.919+0000 I NETWORK  [conn56] end connection 127.0.0.1:47300 (8 connections now open)
2022-03-30T21:18:38.938+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:52188 #57 (9 connections now open)
2022-03-30T21:18:38.939+0000 I NETWORK  [conn57] received client metadata from 127.0.0.1:52188 conn57: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:18:38.944+0000 I NETWORK  [conn57] end connection 127.0.0.1:52188 (8 connections now open)
2022-03-30T21:18:48.880+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:57084 #58 (9 connections now open)
2022-03-30T21:18:48.880+0000 I NETWORK  [conn58] received client metadata from 127.0.0.1:57084 conn58: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:18:48.884+0000 I NETWORK  [conn58] end connection 127.0.0.1:57084 (8 connections now open)
2022-03-30T21:18:58.891+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:35612 #59 (9 connections now open)
2022-03-30T21:18:58.891+0000 I NETWORK  [conn59] received client metadata from 127.0.0.1:35612 conn59: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:18:58.897+0000 I NETWORK  [conn59] end connection 127.0.0.1:35612 (8 connections now open)
2022-03-30T21:19:08.882+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:41014 #60 (9 connections now open)
2022-03-30T21:19:08.883+0000 I NETWORK  [conn60] received client metadata from 127.0.0.1:41014 conn60: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:19:08.887+0000 I NETWORK  [conn60] end connection 127.0.0.1:41014 (8 connections now open)
2022-03-30T21:19:18.898+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:45650 #61 (9 connections now open)
2022-03-30T21:19:18.901+0000 I NETWORK  [conn61] received client metadata from 127.0.0.1:45650 conn61: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:19:18.905+0000 I NETWORK  [conn61] end connection 127.0.0.1:45650 (8 connections now open)
2022-03-30T21:19:28.871+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:50488 #62 (9 connections now open)
2022-03-30T21:19:28.872+0000 I NETWORK  [conn62] received client metadata from 127.0.0.1:50488 conn62: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:19:28.877+0000 I NETWORK  [conn62] end connection 127.0.0.1:50488 (8 connections now open)
2022-03-30T21:19:38.873+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:55002 #63 (9 connections now open)
2022-03-30T21:19:38.873+0000 I NETWORK  [conn63] received client metadata from 127.0.0.1:55002 conn63: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:19:38.882+0000 I NETWORK  [conn63] end connection 127.0.0.1:55002 (8 connections now open)
2022-03-30T21:19:48.886+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:59882 #64 (9 connections now open)
2022-03-30T21:19:48.887+0000 I NETWORK  [conn64] received client metadata from 127.0.0.1:59882 conn64: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:19:48.892+0000 I NETWORK  [conn64] end connection 127.0.0.1:59882 (8 connections now open)
2022-03-30T21:19:58.880+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:37642 #65 (9 connections now open)
2022-03-30T21:19:58.881+0000 I NETWORK  [conn65] received client metadata from 127.0.0.1:37642 conn65: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:19:58.886+0000 I NETWORK  [conn65] end connection 127.0.0.1:37642 (8 connections now open)
2022-03-30T21:20:08.897+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:42470 #66 (9 connections now open)
2022-03-30T21:20:08.897+0000 I NETWORK  [conn66] received client metadata from 127.0.0.1:42470 conn66: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:20:08.902+0000 I NETWORK  [conn66] end connection 127.0.0.1:42470 (8 connections now open)
2022-03-30T21:20:18.984+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:47326 #67 (9 connections now open)
2022-03-30T21:20:18.985+0000 I NETWORK  [conn67] received client metadata from 127.0.0.1:47326 conn67: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:20:18.991+0000 I NETWORK  [conn67] end connection 127.0.0.1:47326 (8 connections now open)
2022-03-30T21:20:28.981+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:52020 #68 (9 connections now open)
2022-03-30T21:20:28.982+0000 I NETWORK  [conn68] received client metadata from 127.0.0.1:52020 conn68: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:20:28.998+0000 I NETWORK  [conn68] end connection 127.0.0.1:52020 (8 connections now open)
2022-03-30T21:20:38.888+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:56826 #69 (9 connections now open)
2022-03-30T21:20:38.889+0000 I NETWORK  [conn69] received client metadata from 127.0.0.1:56826 conn69: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:20:38.893+0000 I NETWORK  [conn69] end connection 127.0.0.1:56826 (8 connections now open)
2022-03-30T21:20:48.866+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:35702 #70 (9 connections now open)
2022-03-30T21:20:48.867+0000 I NETWORK  [conn70] received client metadata from 127.0.0.1:35702 conn70: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:20:48.872+0000 I NETWORK  [conn70] end connection 127.0.0.1:35702 (8 connections now open)
2022-03-30T21:20:58.908+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:40526 #71 (9 connections now open)
2022-03-30T21:20:58.908+0000 I NETWORK  [conn71] received client metadata from 127.0.0.1:40526 conn71: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:20:58.915+0000 I NETWORK  [conn71] end connection 127.0.0.1:40526 (8 connections now open)
2022-03-30T21:21:09.027+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:45370 #72 (9 connections now open)
2022-03-30T21:21:09.027+0000 I NETWORK  [conn72] received client metadata from 127.0.0.1:45370 conn72: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:21:09.032+0000 I NETWORK  [conn72] end connection 127.0.0.1:45370 (8 connections now open)
2022-03-30T21:21:18.876+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:49998 #73 (9 connections now open)
2022-03-30T21:21:18.876+0000 I NETWORK  [conn73] received client metadata from 127.0.0.1:49998 conn73: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:21:18.883+0000 I NETWORK  [conn73] end connection 127.0.0.1:49998 (8 connections now open)
2022-03-30T21:21:28.889+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:54698 #74 (9 connections now open)
2022-03-30T21:21:28.889+0000 I NETWORK  [conn74] received client metadata from 127.0.0.1:54698 conn74: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:21:28.895+0000 I NETWORK  [conn74] end connection 127.0.0.1:54698 (8 connections now open)
2022-03-30T21:21:38.973+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:59682 #75 (9 connections now open)
2022-03-30T21:21:38.976+0000 I NETWORK  [conn75] received client metadata from 127.0.0.1:59682 conn75: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:21:38.990+0000 I NETWORK  [conn75] end connection 127.0.0.1:59682 (8 connections now open)
2022-03-30T21:21:43.498+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:55156 #76 (9 connections now open)
2022-03-30T21:21:43.509+0000 I NETWORK  [conn76] received client metadata from 100.96.83.172:55156 conn76: { driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:21:43.517+0000 I NETWORK  [listener] connection accepted from 100.96.83.172:55160 #77 (10 connections now open)
2022-03-30T21:21:43.517+0000 I NETWORK  [conn77] received client metadata from 100.96.83.172:55160 conn77: { driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:21:43.519+0000 I ACCESS   [conn77] Successfully authenticated as principal __system on local from client 100.96.83.172:55160
2022-03-30T21:21:43.521+0000 I ACCESS   [conn77] Successfully authenticated as principal __system on local from client 100.96.83.172:55160
2022-03-30T21:21:43.523+0000 I ACCESS   [conn77] Successfully authenticated as principal __system on local from client 100.96.83.172:55160
2022-03-30T21:21:43.525+0000 I ACCESS   [conn77] Successfully authenticated as principal __system on local from client 100.96.83.172:55160
2022-03-30T21:21:48.867+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:38080 #78 (11 connections now open)
2022-03-30T21:21:48.867+0000 I NETWORK  [conn78] received client metadata from 127.0.0.1:38080 conn78: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:21:48.872+0000 I NETWORK  [conn78] end connection 127.0.0.1:38080 (10 connections now open)
2022-03-30T21:21:58.881+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:42652 #79 (11 connections now open)
2022-03-30T21:21:58.882+0000 I NETWORK  [conn79] received client metadata from 127.0.0.1:42652 conn79: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:21:58.886+0000 I NETWORK  [conn79] end connection 127.0.0.1:42652 (10 connections now open)
2022-03-30T21:22:07.000+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:46976 #80 (11 connections now open)
2022-03-30T21:22:07.000+0000 I NETWORK  [conn80] received client metadata from 100.96.78.144:46976 conn80: { driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:22:07.002+0000 I NETWORK  [listener] connection accepted from 100.96.78.144:46978 #81 (12 connections now open)
2022-03-30T21:22:07.003+0000 I NETWORK  [conn81] received client metadata from 100.96.78.144:46978 conn81: { driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-7-amd64" } }
2022-03-30T21:22:07.005+0000 I ACCESS   [conn81] Successfully authenticated as principal __system on local from client 100.96.78.144:46978
2022-03-30T21:22:07.007+0000 I ACCESS   [conn81] Successfully authenticated as principal __system on local from client 100.96.78.144:46978
2022-03-30T21:22:07.020+0000 I ACCESS   [conn81] Successfully authenticated as principal __system on local from client 100.96.78.144:46978
2022-03-30T21:22:07.022+0000 I ACCESS   [conn81] Successfully authenticated as principal __system on local from client 100.96.78.144:46978
2022-03-30T21:22:08.874+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:47494 #82 (13 connections now open)
2022-03-30T21:22:08.874+0000 I NETWORK  [conn82] received client metadata from 127.0.0.1:47494 conn82: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:22:08.878+0000 I NETWORK  [conn82] end connection 127.0.0.1:47494 (12 connections now open)
2022-03-30T21:22:18.893+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:52364 #83 (13 connections now open)
2022-03-30T21:22:18.894+0000 I NETWORK  [conn83] received client metadata from 127.0.0.1:52364 conn83: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:22:18.900+0000 I NETWORK  [conn83] end connection 127.0.0.1:52364 (12 connections now open)
2022-03-30T21:22:28.878+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:58834 #84 (13 connections now open)
2022-03-30T21:22:28.879+0000 I NETWORK  [conn84] received client metadata from 127.0.0.1:58834 conn84: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:22:28.883+0000 I NETWORK  [conn84] end connection 127.0.0.1:58834 (12 connections now open)
2022-03-30T21:22:38.861+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:35484 #85 (13 connections now open)
2022-03-30T21:22:38.861+0000 I NETWORK  [conn85] received client metadata from 127.0.0.1:35484 conn85: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:22:38.865+0000 I NETWORK  [conn85] end connection 127.0.0.1:35484 (12 connections now open)
2022-03-30T21:22:48.967+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:40338 #86 (13 connections now open)
2022-03-30T21:22:48.968+0000 I NETWORK  [conn86] received client metadata from 127.0.0.1:40338 conn86: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:22:48.982+0000 I NETWORK  [conn86] end connection 127.0.0.1:40338 (12 connections now open)
2022-03-30T21:22:58.923+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:47576 #87 (13 connections now open)
2022-03-30T21:22:58.923+0000 I NETWORK  [conn87] received client metadata from 127.0.0.1:47576 conn87: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:22:58.928+0000 I NETWORK  [conn87] end connection 127.0.0.1:47576 (12 connections now open)
2022-03-30T21:23:08.943+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:52300 #88 (13 connections now open)
2022-03-30T21:23:08.944+0000 I NETWORK  [conn88] received client metadata from 127.0.0.1:52300 conn88: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:23:08.949+0000 I NETWORK  [conn88] end connection 127.0.0.1:52300 (12 connections now open)
2022-03-30T21:23:18.876+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:57182 #89 (13 connections now open)
2022-03-30T21:23:18.877+0000 I NETWORK  [conn89] received client metadata from 127.0.0.1:57182 conn89: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:23:18.881+0000 I NETWORK  [conn89] end connection 127.0.0.1:57182 (12 connections now open)
2022-03-30T21:23:28.887+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:33902 #90 (13 connections now open)
2022-03-30T21:23:28.888+0000 I NETWORK  [conn90] received client metadata from 127.0.0.1:33902 conn90: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:23:28.892+0000 I NETWORK  [conn90] end connection 127.0.0.1:33902 (12 connections now open)
2022-03-30T21:23:38.922+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:38732 #91 (13 connections now open)
2022-03-30T21:23:38.923+0000 I NETWORK  [conn91] received client metadata from 127.0.0.1:38732 conn91: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:23:38.927+0000 I NETWORK  [conn91] end connection 127.0.0.1:38732 (12 connections now open)
2022-03-30T21:23:48.878+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:43312 #92 (13 connections now open)
2022-03-30T21:23:48.878+0000 I NETWORK  [conn92] received client metadata from 127.0.0.1:43312 conn92: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:23:48.882+0000 I NETWORK  [conn92] end connection 127.0.0.1:43312 (12 connections now open)
2022-03-30T21:23:59.024+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:48128 #93 (13 connections now open)
2022-03-30T21:23:59.024+0000 I NETWORK  [conn93] received client metadata from 127.0.0.1:48128 conn93: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:23:59.030+0000 I NETWORK  [conn93] end connection 127.0.0.1:48128 (12 connections now open)
2022-03-30T21:24:08.872+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:52770 #94 (13 connections now open)
2022-03-30T21:24:08.873+0000 I NETWORK  [conn94] received client metadata from 127.0.0.1:52770 conn94: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:24:08.877+0000 I NETWORK  [conn94] end connection 127.0.0.1:52770 (12 connections now open)
2022-03-30T21:24:18.860+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:59688 #95 (13 connections now open)
2022-03-30T21:24:18.860+0000 I NETWORK  [conn95] received client metadata from 127.0.0.1:59688 conn95: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:24:18.863+0000 I NETWORK  [conn95] end connection 127.0.0.1:59688 (12 connections now open)
2022-03-30T21:24:28.881+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:37298 #96 (13 connections now open)
2022-03-30T21:24:28.884+0000 I NETWORK  [conn96] received client metadata from 127.0.0.1:37298 conn96: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:24:28.891+0000 I NETWORK  [conn96] end connection 127.0.0.1:37298 (12 connections now open)
2022-03-30T21:24:38.864+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:42132 #97 (13 connections now open)
2022-03-30T21:24:38.864+0000 I NETWORK  [conn97] received client metadata from 127.0.0.1:42132 conn97: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:24:38.869+0000 I NETWORK  [conn97] end connection 127.0.0.1:42132 (12 connections now open)
2022-03-30T21:24:48.886+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:46980 #98 (13 connections now open)
2022-03-30T21:24:48.886+0000 I NETWORK  [conn98] received client metadata from 127.0.0.1:46980 conn98: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:24:48.891+0000 I NETWORK  [conn98] end connection 127.0.0.1:46980 (12 connections now open)
2022-03-30T21:24:58.905+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:51756 #99 (13 connections now open)
2022-03-30T21:24:58.905+0000 I NETWORK  [conn99] received client metadata from 127.0.0.1:51756 conn99: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:24:58.909+0000 I NETWORK  [conn99] end connection 127.0.0.1:51756 (12 connections now open)
2022-03-30T21:25:08.898+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:56440 #100 (13 connections now open)
2022-03-30T21:25:08.899+0000 I NETWORK  [conn100] received client metadata from 127.0.0.1:56440 conn100: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:25:08.904+0000 I NETWORK  [conn100] end connection 127.0.0.1:56440 (12 connections now open)
2022-03-30T21:25:18.897+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:34138 #101 (13 connections now open)
2022-03-30T21:25:18.897+0000 I NETWORK  [conn101] received client metadata from 127.0.0.1:34138 conn101: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:25:18.901+0000 I NETWORK  [conn101] end connection 127.0.0.1:34138 (12 connections now open)
2022-03-30T21:25:28.893+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:38982 #102 (13 connections now open)
2022-03-30T21:25:28.893+0000 I NETWORK  [conn102] received client metadata from 127.0.0.1:38982 conn102: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:25:28.897+0000 I NETWORK  [conn102] end connection 127.0.0.1:38982 (12 connections now open)
2022-03-30T21:25:38.909+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:43810 #103 (13 connections now open)
2022-03-30T21:25:38.910+0000 I NETWORK  [conn103] received client metadata from 127.0.0.1:43810 conn103: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:25:38.915+0000 I NETWORK  [conn103] end connection 127.0.0.1:43810 (12 connections now open)
2022-03-30T21:25:48.878+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:48662 #104 (13 connections now open)
2022-03-30T21:25:48.879+0000 I NETWORK  [conn104] received client metadata from 127.0.0.1:48662 conn104: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:25:48.884+0000 I NETWORK  [conn104] end connection 127.0.0.1:48662 (12 connections now open)
2022-03-30T21:25:58.903+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:53382 #105 (13 connections now open)
2022-03-30T21:25:58.903+0000 I NETWORK  [conn105] received client metadata from 127.0.0.1:53382 conn105: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:25:58.909+0000 I NETWORK  [conn105] end connection 127.0.0.1:53382 (12 connections now open)
2022-03-30T21:26:08.875+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:60416 #106 (13 connections now open)
2022-03-30T21:26:08.876+0000 I NETWORK  [conn106] received client metadata from 127.0.0.1:60416 conn106: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:26:08.882+0000 I NETWORK  [conn106] end connection 127.0.0.1:60416 (12 connections now open)
2022-03-30T21:26:18.891+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:37040 #107 (13 connections now open)
2022-03-30T21:26:18.892+0000 I NETWORK  [conn107] received client metadata from 127.0.0.1:37040 conn107: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:26:18.898+0000 I NETWORK  [conn107] end connection 127.0.0.1:37040 (12 connections now open)
2022-03-30T21:26:28.876+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:41890 #108 (13 connections now open)
2022-03-30T21:26:28.877+0000 I NETWORK  [conn108] received client metadata from 127.0.0.1:41890 conn108: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:26:28.882+0000 I NETWORK  [conn108] end connection 127.0.0.1:41890 (12 connections now open)
2022-03-30T21:26:38.905+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:46746 #109 (13 connections now open)
2022-03-30T21:26:38.905+0000 I NETWORK  [conn109] received client metadata from 127.0.0.1:46746 conn109: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:26:38.909+0000 I NETWORK  [conn109] end connection 127.0.0.1:46746 (12 connections now open)
2022-03-30T21:26:43.499+0000 I ACCESS   [conn77] Successfully authenticated as principal __system on local from client 100.96.83.172:55160
2022-03-30T21:26:43.501+0000 I ACCESS   [conn77] Successfully authenticated as principal __system on local from client 100.96.83.172:55160
2022-03-30T21:26:43.503+0000 I ACCESS   [conn77] Successfully authenticated as principal __system on local from client 100.96.83.172:55160
2022-03-30T21:26:43.505+0000 I ACCESS   [conn77] Successfully authenticated as principal __system on local from client 100.96.83.172:55160
2022-03-30T21:26:48.897+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:51572 #110 (13 connections now open)
2022-03-30T21:26:48.901+0000 I NETWORK  [conn110] received client metadata from 127.0.0.1:51572 conn110: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:26:48.911+0000 I NETWORK  [conn110] end connection 127.0.0.1:51572 (12 connections now open)
2022-03-30T21:26:58.915+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:56314 #111 (13 connections now open)
2022-03-30T21:26:58.915+0000 I NETWORK  [conn111] received client metadata from 127.0.0.1:56314 conn111: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:26:58.919+0000 I NETWORK  [conn111] end connection 127.0.0.1:56314 (12 connections now open)
2022-03-30T21:27:07.001+0000 I ACCESS   [conn81] Successfully authenticated as principal __system on local from client 100.96.78.144:46978
2022-03-30T21:27:07.004+0000 I ACCESS   [conn81] Successfully authenticated as principal __system on local from client 100.96.78.144:46978
2022-03-30T21:27:07.019+0000 I ACCESS   [conn81] Successfully authenticated as principal __system on local from client 100.96.78.144:46978
2022-03-30T21:27:07.021+0000 I ACCESS   [conn81] Successfully authenticated as principal __system on local from client 100.96.78.144:46978
2022-03-30T21:27:08.918+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:34876 #112 (13 connections now open)
2022-03-30T21:27:08.919+0000 I NETWORK  [conn112] received client metadata from 127.0.0.1:34876 conn112: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:27:08.926+0000 I NETWORK  [conn112] end connection 127.0.0.1:34876 (12 connections now open)
2022-03-30T21:27:18.888+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:39788 #113 (13 connections now open)
2022-03-30T21:27:18.889+0000 I NETWORK  [conn113] received client metadata from 127.0.0.1:39788 conn113: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:27:18.894+0000 I NETWORK  [conn113] end connection 127.0.0.1:39788 (12 connections now open)
2022-03-30T21:27:28.897+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:44630 #114 (13 connections now open)
2022-03-30T21:27:28.901+0000 I NETWORK  [conn114] received client metadata from 127.0.0.1:44630 conn114: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:27:28.909+0000 I NETWORK  [conn114] end connection 127.0.0.1:44630 (12 connections now open)
2022-03-30T21:27:38.956+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:49456 #115 (13 connections now open)
2022-03-30T21:27:38.957+0000 I NETWORK  [conn115] received client metadata from 127.0.0.1:49456 conn115: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:27:38.971+0000 I NETWORK  [conn115] end connection 127.0.0.1:49456 (12 connections now open)
2022-03-30T21:27:48.868+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:55680 #116 (13 connections now open)
2022-03-30T21:27:48.868+0000 I NETWORK  [conn116] received client metadata from 127.0.0.1:55680 conn116: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:27:48.872+0000 I NETWORK  [conn116] end connection 127.0.0.1:55680 (12 connections now open)
2022-03-30T21:27:58.888+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:60572 #117 (13 connections now open)
2022-03-30T21:27:58.889+0000 I NETWORK  [conn117] received client metadata from 127.0.0.1:60572 conn117: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:27:58.898+0000 I NETWORK  [conn117] end connection 127.0.0.1:60572 (12 connections now open)
2022-03-30T21:28:08.895+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:36814 #118 (13 connections now open)
2022-03-30T21:28:08.895+0000 I NETWORK  [conn118] received client metadata from 127.0.0.1:36814 conn118: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:28:08.900+0000 I NETWORK  [conn118] end connection 127.0.0.1:36814 (12 connections now open)
2022-03-30T21:28:18.906+0000 I NETWORK  [listener] connection accepted from 127.0.0.1:43484 #119 (13 connections now open)
2022-03-30T21:28:18.908+0000 I NETWORK  [conn119] received client metadata from 127.0.0.1:43484 conn119: { application: { name: "MongoDB Shell" }, driver: { name: "MongoDB Internal Client", version: "4.0.12" }, os: { type: "Linux", name: "PRETTY_NAME="Debian GNU/Linux 9 (stretch)"", architecture: "x86_64", version: "Kernel 4.9.0-11-amd64" } }
2022-03-30T21:28:18.916+0000 I NETWORK  [conn119] end connection 127.0.0.1:43484 (12 connections now open)




(base) LSKI2813:~ lix2$ kubectl logs gn-mongo-v0dot23-grch38-ensembl95-mongodb-primary-0 --namespace genome-nexus -c metrics
time="2022-03-30T21:15:54Z" level=info msg="Starting mongodb_exporter (version=0.10.0, branch=v0.10.0, revision=bf683745093a9210ebacbeb235bb792e21d17389)" source="mongodb_exporter.go:94"
time="2022-03-30T21:15:54Z" level=info msg="Build context (go=go1.12.9, user=travis@build.travis-ci.com, date=20190918-08:07:48)" source="mongodb_exporter.go:95"
time="2022-03-30T21:15:57Z" level=info msg="Starting HTTP server for http://:9216/metrics ..." source="server.go:140"
time="2022-03-30T21:16:08Z" level=error msg="Could not get MongoDB BuildInfo: connection(localhost:27017[-17]) unable to decode message length: read tcp 127.0.0.1:56336->127.0.0.1:27017: read: connection reset by peer!" source="connection.go:98"
time="2022-03-30T21:16:08Z" level=error msg="Problem gathering the mongo server version: connection(localhost:27017[-17]) unable to decode message length: read tcp 127.0.0.1:56336->127.0.0.1:27017: read: connection reset by peer" source="mongodb_collector.go:203"




(base) LSKI2813:~ lix2$ kubectl logs gn-mongo-v0dot23-grch38-ensembl95-mongodb-secondary-0 --namespace genome-nexus -c metrics
time="2022-03-30T21:15:56Z" level=info msg="Starting mongodb_exporter (version=0.10.0, branch=v0.10.0, revision=bf683745093a9210ebacbeb235bb792e21d17389)" source="mongodb_exporter.go:94"
time="2022-03-30T21:15:56Z" level=info msg="Build context (go=go1.12.9, user=travis@build.travis-ci.com, date=20190918-08:07:48)" source="mongodb_exporter.go:95"
time="2022-03-30T21:16:00Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:00Z" level=info msg="Starting HTTP server for http://:9216/metrics ..." source="server.go:140"
time="2022-03-30T21:16:04Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:09Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:11Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:14Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:16Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:19Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:21Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:24Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:26Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:29Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:31Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:34Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:36Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:39Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:41Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:44Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:46Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:49Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:51Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:54Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:56Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:16:59Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:17:01Z" level=error msg="Failed to get server status: (Unauthorized) not authorized on admin to execute command { serverStatus: 1, recordStats: 0, opLatencies: { histograms: true }, lsid: { id: UUID(\"d2c4f2dc-8517-4238-b077-f5e6db1c71b6\") }, $db: \"admin\", $readPreference: { mode: \"primaryPreferred\" } }" source="server_status.go:151"
time="2022-03-30T21:17:04Z" level=error msg="Failed to get server status: (Unauthorized) command serverStatus requires authentication" source="server_status.go:151"
time="2022-03-30T21:17:04Z" level=error msg="Failed to get replSetGetConfig: (Unauthorized) command replSetGetConfig requires authentication." source="replset_conf.go:115"
time="2022-03-30T21:17:04Z" level=error msg="Failed to get replSet status: (Unauthorized) command replSetGetStatus requires authentication" source="replset_status.go:307"
time="2022-03-30T21:17:04Z" level=error msg="Failed to get oplog collection status: (Unauthorized) command collStats requires authentication" source="oplog_status.go:144"
time="2022-03-30T21:17:04Z" level=error msg="Failed to get oplog timestamps status: (Unauthorized) command find requires authentication" source="oplog_status.go:149"
time="2022-03-30T21:17:06Z" level=error msg="Could not get MongoDB BuildInfo: connection(localhost:27017[-17]) unable to decode message length: EOF!" source="connection.go:98"
time="2022-03-30T21:17:06Z" level=error msg="Problem gathering the mongo server version: connection(localhost:27017[-17]) unable to decode message length: EOF" source="mongodb_collector.go:203"