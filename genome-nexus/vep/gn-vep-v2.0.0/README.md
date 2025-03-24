# Options for setting up VEP

## Easist (Currently in production)

The current solution achieves performance comparable to the Ensembl Public API. Simply apply the `gn-vep-2.yaml` config (or `gn-vep-2-extended.yaml` for AlphaMissense and PolyPhen/SIFT predictions), and make sure to supply the database credentials through a Secret. Our current production setup connects to an RDS instance.

## Max Performance

Important notes before you begin:

1. Much of the config in `gn-vep-2-mysql.yaml` is based around specific machines that exist in our ecosystem. Usage may requiring changing node selectors to suit your needs.
2. For each replica of the mysql pod, 15GB of storage is required on the chosen node. Issues may arise if your node does not have enough disk storage.
3. One common pitfall is a non-empty persistent volume mounted to `/var/lib/mysql`. If this directory is non-empty, the mysql entrypoint script that initializes the data will not run. 
If you observe this behavior, try going into the volume and removing all data.

In order to achieve much better performance, it is important that the MySQL server lives on the same node as the MySQL client. For this solution perform the following steps to connect to a node local database rather than RDS:

1. Apply `local-path-provisioner.yaml`.
2. Apply `gn-vep-2-mysql.yaml`. Make sure that there is a secret named  `homo-sapiens-core-db-creds` that specifies `mysql-user`, `mysql-password`, and `mysql-root-password`.
3. Make changes to `gn-vep-2.yaml` (or `gn-vep-2-extended.yaml`) so the secret it uses is for connecting to your newly created MySQL service. By default it is setup to connect to RDS.
4. Apply `gn-vep-2.yaml` (or `gn-vep-2-extended.yaml`).
5. Run `kubectl cp {PATH TO homo_sapiens_core_112_37.sql} homo-sapiens-core-mysql-0:/dumps -c wait-for-sql-dump`. To observe progress, you can run 
`kubectl logs -f homo-sapiens-core-mysql-0 -c wait-for-sql-dump`.
6. Wait for each pod to finish importing the SQL dump. Your application is now ready for use.