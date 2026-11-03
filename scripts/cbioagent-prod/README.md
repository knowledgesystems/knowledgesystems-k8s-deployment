# cbioagent prod agent tool list

The prod cBioPortalChat agent (`agent_9ZXhcwLIsROBQX0u4JS5F`, the `agent_id` in [`librechat-config.yaml`](../../argocd/aws/203403084713/clusters/cbioportal-prod/apps/cbioagent/librechat-config.yaml)) keeps its tool list in MongoDB and names its `cbioportal-database` tools one by one. A tool added to the MCP server stays invisible to the agent until it is added to that list.

[`add_domain_tools.py`](add_domain_tools.py) adds the four tools from cbioportal-mcp #154:

- `get_alteration_frequency_mcp_cbioportal-database`
- `get_top_altered_genes_mcp_cbioportal-database`
- `get_gene_frequency_by_cancer_type_mcp_cbioportal-database`
- `get_profiled_counts_mcp_cbioportal-database`

It writes only that agent's `tools` and `updatedAt`, and pushes a new entry onto `versions`. It doesn't touch `aclentries` or the instructions, and it has no option to target another agent. It's a dry run unless you pass `--apply`. Re-running is safe. The script stops without writing if the agent is missing or duplicated, has no `cbioportal-database` tools, or changed while the script ran. An agent with the all-tools entry (`sys__all__sys_mcp_cbioportal-database`) already gets the new tools, so it's left alone.

## Run

MongoDB is shared with beta. Run this **after** the prod `cbioagent-clickhouse-mcp` pod has rolled to an image with #154, so the agent never lists tools the server doesn't have. This prints `True` once the running image has them:

```bash
kubectl exec deploy/cbioagent-clickhouse-mcp -- python -c "import importlib.util as u; print(bool(u.find_spec('cbioportal_mcp.domain_tools')))"
```

Then:

```bash
pip install pymongo
# Port-forward the shared MongoDB (cbioportal-prod cluster, default namespace)
kubectl port-forward svc/cbioagent-mongodb 27017:27017 &
# MONGO_URI is in the librechat-credentials-env Secret (portal-configuration); point its host at localhost:27017
export MONGO_URI='mongodb://<user>:<pass>@localhost:27017/cBioAgent?authSource=admin'

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
