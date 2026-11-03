# cbioagent prod agent tool list

The prod cBioPortalChat agent (`agent_9ZXhcwLIsROBQX0u4JS5F`, the `agent_id` in [`librechat-config.yaml`](../../argocd/aws/203403084713/clusters/cbioportal-prod/apps/cbioagent/librechat-config.yaml)) keeps its tool list in MongoDB and names its `cbioportal-database` tools one by one. A tool added to the MCP server stays invisible to the agent until it is added to that list.

[`add_domain_tools.py`](add_domain_tools.py) adds the four tools from cbioportal-mcp #154:

- `get_alteration_frequency_mcp_cbioportal-database`
- `get_top_altered_genes_mcp_cbioportal-database`
- `get_gene_frequency_by_cancer_type_mcp_cbioportal-database`
- `get_profiled_counts_mcp_cbioportal-database`

It writes only that agent's `tools` and `updatedAt`, and pushes a new entry onto `versions`. It doesn't touch `aclentries` or the instructions, and it has no option to target another agent. It's a dry run unless you pass `--apply`. Re-running is safe. The script stops without writing if the agent is missing or duplicated, has no `cbioportal-database` tools, or changed while the script ran. An agent with the all-tools entry (`sys__all__sys_mcp_cbioportal-database`) already gets the new tools, so it's left alone.

## Connect

MongoDB is shared with beta. The port-forward and the commands in [Inspect](#inspect-read-only) only read, and the password stays in the environment variable; nothing below prints it.

```bash
pip install pymongo
# Port-forward the shared MongoDB (cbioportal-prod cluster, default namespace)
kubectl port-forward -n default svc/cbioagent-mongodb 27017:27017 &
# Take MONGO_URI from the Secret and point its host at the port-forward.
# If the URI has a replicaSet parameter, also add directConnection=true.
export MONGO_URI="$(kubectl get secret librechat-credentials-env -n default -o jsonpath='{.data.MONGO_URI}' | base64 -d | sed -E 's#@[^/]+/#@localhost:27017/#')"
```

## Inspect (read-only)

Run this before the rollout. It reads that one document and returns only `tools`:

```bash
python -c "
import os, pymongo
db = pymongo.MongoClient(os.environ['MONGO_URI'], serverSelectionTimeoutMS=10000).get_default_database('cBioAgent')
docs = list(db.agents.find({'id': 'agent_9ZXhcwLIsROBQX0u4JS5F'}, {'_id': 0, 'tools': 1}))
print(len(docs), 'document(s)')
for d in docs: print(*d.get('tools', []), sep='\n')
"
```

Expect one document, with `cbioportal-database` tools named one by one and none of the four above. Stop and investigate anything else, unless it's the all-tools entry, which means no change is needed.

The script's dry run (`./add_domain_tools.py`, no `--apply`) also only reads, and doesn't contact the MCP server, so it can run before the rollout too. It prints the tools it would add and the before and after counts, but not the full list.

## Run

Run `--apply` only when **both** of these are true, so the agent never lists tools the server doesn't have, and the tools don't report numbers from the old views:

1. The prod `cbioagent-clickhouse-mcp` pod has rolled to an image with #154. This prints `True`:
   ```bash
   kubectl exec -n default deploy/cbioagent-clickhouse-mcp -- /app/.venv/bin/python -c "import importlib.util as u; print(bool(u.find_spec('cbioportal_mcp.domain_tools')))"
   ```
2. A clone from that image has applied the new `sql/4` to the serving database. `get_gene_frequency_by_cancer_type` reads one of its views. This should print `UNCALLED 2` and `NOT IN 1` (the old views give 1 and 0):
   ```bash
   kubectl exec -n default deploy/cbioagent-clickhouse-mcp -- /app/.venv/bin/python -c "
   from mcp_clickhouse.mcp_server import create_clickhouse_client as c
   q = c()
   print('serving', q.query('SELECT currentDatabase()').result_rows[0][0])
   print('UNCALLED', q.query('SHOW CREATE VIEW gene_alteration_frequency_by_cancer_type').result_rows[0][0].count('UNCALLED'))
   print('NOT IN', q.query('SHOW CREATE VIEW top_mutated_genes_in_study').result_rows[0][0].count('NOT IN'))
   "
   ```

Then:

```bash
./add_domain_tools.py           # dry run: expect "would add on agent_9ZXh... (N -> N+4 tools)" and the four names
./add_domain_tools.py --apply   # expect "add on agent_9ZXh..."
./add_domain_tools.py           # expect "unchanged agent_9ZXh..."
```

To test, start a **new** chat and ask, for example, "What percentage of samples in msk_impact_2017 have a KRAS mutation?", then confirm it calls `get_alteration_frequency`. If the tool doesn't appear, restart the LibreChat pod and try again.

## Roll back

Take the tools out **before** rolling the image back, so the agent never lists tools the server doesn't have:

```bash
./add_domain_tools.py --remove          # dry run
./add_domain_tools.py --remove --apply
```

## Tests

```bash
pip install pymongo mongomock
python -m unittest scripts/cbioagent-prod/test_add_domain_tools.py
```
