# Genome Nexus Mongodb Volumes
resource "aws_ebs_volume" "gn-mongo-v1dot0-mongodb" {
  availability_zone = var.GENOMENEXUS_EBS_VOLUME_AZ
  size              = 300
  type              = "gp3"

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

resource "aws_ebs_volume" "gn-mongo-v0dot32-grch38-ensembl95-mongodb" {
  availability_zone = var.GENOMENEXUS_EBS_VOLUME_AZ
  snapshot_id       = "snap-09872413811317dc9"
  size              = 500
  type              = "gp3"

  tags = {
    Name          = "gn-mongo-v0dot32-grch38-ensembl95-mongodb"
    cdsi-app      = "genome-nexus"
    cdsi-team     = "data-engineering"
    cdsi-owner    = "lix2@mskcc.org"
    resource-name = "gn-mongo-v0dot32-grch38-ensembl95-mongodb"
  }

  lifecycle {
    prevent_destroy = true
  }
}