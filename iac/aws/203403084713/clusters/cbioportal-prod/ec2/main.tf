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

output "gn_mongo_v1dot0_volume_id" {
  value = aws_ebs_volume.gn-mongo-v1dot0-mongodb.id
}

resource "aws_ebs_volume" "gn-mongo-v0dot32-grch38-ensembl95-mongodb" {
  availability_zone = var.GENOMENEXUS_EBS_VOLUME_AZ
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

output "gn_mongo_v0dot32_grch38_volume_id" {
  value = aws_ebs_volume.gn-mongo-v0dot32-grch38-ensembl95-mongodb.id
}

resource "aws_ebs_volume" "gn-mongo-v1dot2-grch37-ensembl111-mongodb" {
  availability_zone = var.GENOMENEXUS_EBS_VOLUME_AZ
  snapshot_id       = "snap-071a48a83cc7e76b5"
  size              = 300
  type              = "gp3"

  tags = {
    Name          = "gn-mongo-v1dot2-grch37-ensembl111-mongodb"
    cdsi-app      = "genome-nexus"
    cdsi-team     = "data-engineering"
    cdsi-owner    = "lix2@mskcc.org"
    resource-name = "gn-mongo-v1dot2-grch37-ensembl111-mongodb"
  }

  lifecycle {
    prevent_destroy = true
  }
}