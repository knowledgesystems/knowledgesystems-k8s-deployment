# Genome Nexus Mongodb Volumes
resource "aws_ebs_volume" "gn-mongo-v1dot0-mongodb" {
  availability_zone = var.GENOMENEXUS_EBS_VOLUME_AZ
  snapshot_id       = "snap-05b889983c9ab347a"
  type              = "gp2"

  tags = {
    Name          = "gn-mongo-v1dot0-mongodb"
    cdsi-app      = "genome-nexus"
    cdsi-team     = "data-engineering"
    cdsi-owner    = "lix2@mskcc.org"
    resource-name = "gn-mongo-v1dot0-mongodb"
  }

  lifecycle {
    prevent_destroy = true
  }
}