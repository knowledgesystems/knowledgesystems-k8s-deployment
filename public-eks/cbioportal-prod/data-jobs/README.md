# Data Jobs related to cBioPortal

## Sync rc database with production database
We use a different database for our rc development branch occasinally when it
needs a different database version. See also:
https://github.com/cBioPortal/cbioportal/blob/master/CONTRIBUTING.md#branches-within-cbioportal.

To sync the database run:

```
kubectl apply -f sync_rc_db.yaml
```
Make sure to delete the job again after
```
kubectl delete -f sync_rc_db.yaml
```
See [sync_rc_db.yaml](sync_rc_db.yaml) for the script.
