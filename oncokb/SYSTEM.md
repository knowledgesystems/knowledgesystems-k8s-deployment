# OncoKB System
This is the documentation describing the current running apps in varies production environments.


## Environments

### oncokb.org
- All apps under oncokb.org is managed by k8s. 
- Cluster is in us-east-1
- We shared the AWS account with cBioPortal. Please reach out to Ino de Bruijn(debruiji@mskcc.org) for access
  - Currently, Hongxin Zhang, Calvin Lu and Stephanie Carrero have the access to the prod cluster

### eucentral.oncokb.org
- All apps under eucentral.oncokb.org is managed by k8s.
- Cluster is in eu-central-1
- We shared the AWS account with cBioPortal. Please reach out to Ino de Bruijn(debruiji@mskcc.org) for access
    - Currently, Hongxin Zhang, Calvin Lu and Stephanie Carrero have the access to the prod cluster

### oncokb.aws.mskcc.org
- All apps under oncokb.dev.aws.mskcc.org is managed by k8s.
- Cluster is in us-east-1
- We use standard private VPC account from MSK. Please reach out to [MSK security for access](https://thespot.mskcc.org/esc/?id=sc_cat_item&sys_id=cee42b7cdb09a010701a2a591396198b).
    - Currently, Hongxin Zhang, Calvin Lu and Stephanie Carrero have the access to the prod cluster

### oncokb.dev.aws.mskcc.org
- All apps under oncokb.dev.aws.mskcc.org is managed by k8s.
- Cluster is in us-east-1
- We use standard private VPC account from MSK. Please reach out to [MSK security for access](https://thespot.mskcc.org/esc/?id=sc_cat_item&sys_id=cee42b7cdb09a010701a2a591396198b).
    - Currently, Hongxin Zhang, Calvin Lu and Stephanie Carrero have the access to the prod cluster

### on-premise server
- Server Address: **dashi.cbio.mskcc.org:38080**
  - Only Hongxin/Ino and few members from the backend team have access
- DB address: **pipelines.cbioportal.mskcc.org** 
  - Only Hongxin/Ino and few members from the backend team have access
- Release
  1. Reach out to hongxin for credentials(This is a legacy server, I don't believe we can create new accounts)
  2. Update `GDRP`, `GDProps` and `ONCOKBPATH` path before running. Properties are located at [**HERE**](https://github.com/knowledgesystems/oncokb-deployment/tree/master/credentails/on-premise/properties)
  3. Run script on-premise/release_dashi.sh
  4. The script will upload newly generated apps to server
- Apps
  - dashi.cbio.mskcc.org:38080/curate and oncokb.mskcc.org/curate 
    - Lead to the same instance which is our curation platform
    - This is the production app that have all OncoKB curation info included.
  - dashi.cbio.mskcc.org:38080/internal/
    - This is used by MSK cBioPortal and also is incharge of saving data and propagating to other instances
  - dashi.cbio.mskcc.org:38080/cbx/ 
    - This is a dedicated instance for MPath/CVR
  - dashi.cbio.mskcc.org:38080/beta/
    - This is a backup instance for MPath/CVR
