# Temp Webinar instance

Steps to set up a temp webinar instance

1. Create new db instance on AWS RDS
    - Go to RDS page, click on snapshots, click on System, click on action >
      restore
    - Select a big database, i usually double it: db.r5.4xlarge
    - set security group is to allow connections from anywhere (or the k8s nodes). rds-launchwizard-5 seems to work. Prolly good to rename. I guess anything that allows 3306 access to the relevant IPs
    - mysql conf is the same as production db (that is it allows bigger packets etc). It's called cbioportla-mysql-conf or something
2. Increase number of nodes in large-mem group (this requires kops access)
3. Point db host parameters in this folder to the newly setup AWS RDS node
4. kubectl apply the yaml in this folder


NOTE: if you are setting up a new URL make sure to add it to the allowed redirects in google auth
