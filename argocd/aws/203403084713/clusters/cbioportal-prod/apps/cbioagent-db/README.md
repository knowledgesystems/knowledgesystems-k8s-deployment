# cbioagent-db

MongoDB and PostgreSQL databases for the cbioagent (LibreChat) deployment.

## MongoDB

Bitnami MongoDB Helm chart (`mongodb-16.5.45`), standalone architecture.

- **Database:** `cBioAgent`
- **App user:** `cbioagent` (readWrite, used by LibreChat)
- **Credentials:** `cbioagent-mongodb-creds` secret
- **PVC:** `cbioagent-mongodb` (500Gi, `resourcePolicy: keep`)

### Extra Users (created manually, not in Helm values)

The following users are created at runtime and persist in the PVC data directory. They survive pod restarts but would need to be recreated after a full Helm reinstall (unlikely given `resourcePolicy: keep`).

| User | Role | Database | Purpose |
|------|------|----------|---------|
| `readonly_dev` | `read` | `cBioAgent` | External contributor access via kubectl port-forward |

The Bitnami chart only supports `readWrite` users via `auth.usernames`, so read-only users must be created manually:

```bash
# Find the MongoDB pod
kubectl get pods | grep cbioagent-mongodb

# Create/recreate the readonly_dev user
kubectl exec <mongodb-pod> -- mongosh --quiet \
  -u root -p '<root-password>' --authenticationDatabase admin --eval '
db = db.getSiblingDB("cBioAgent");
try { db.dropUser("readonly_dev"); } catch(e) {}
db.createUser({
  user: "readonly_dev",
  pwd: "cbio-dev-ro-2026",
  roles: [{ role: "read", db: "cBioAgent" }]
});
'
```

Root password is in the `cbioagent-mongodb-creds` secret (`mongodb-root-password` key).

### External Developer Access

See `portal-configuration` repo: `argocd/aws/203403084713/clusters/cbioportal-prod/service-accounts/external-devs/README.md` for kubeconfigs and instructions.
