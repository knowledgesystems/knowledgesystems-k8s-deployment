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

output "gn-mongo-v1dot2-grch37-ensembl111_volume_id" {
  value = aws_ebs_volume.gn-mongo-v1dot2-grch37-ensembl111-mongodb.id
}

resource "aws_ebs_volume" "gn-mongo-vep111-mongodb" {
  availability_zone = var.GENOMENEXUS_EBS_VOLUME_AZ
  size              = 150
  type              = "gp3"
  snapshot_id       = "snap-007ecb59d110c39ec"

  tags = {
    Name          = "gn-mongo-vep111-mongodb"
    cdsi-app      = "genome-nexus"
    cdsi-team     = "data-engineering"
    cdsi-owner    = "lix2@mskcc.org"
    resource-name = "gn-mongo-vep111-mongodb"
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "gn_mongo_vep111_volume_id" {
  value = aws_ebs_volume.gn-mongo-vep111-mongodb.id
}

resource "aws_ebs_volume" "gn-mongo-gnap-mongodb" {
  availability_zone = var.GENOMENEXUS_EBS_VOLUME_AZ
  size              = 100
  type              = "gp3"
  snapshot_id       = "snap-080b041320a36270d"

  tags = {
    Name          = "gn-mongo-gnap-mongodb"
    cdsi-app      = "genome-nexus"
    cdsi-team     = "data-engineering"
    cdsi-owner    = "lix2@mskcc.org"
    resource-name = "gn-mongo-gnap-mongodb"
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "gn_mongo_gnap_volume_id" {
  value = aws_ebs_volume.gn-mongo-gnap-mongodb.id
}

resource "aws_ebs_volume" "gn-mongo-genie-mongodb" {
  availability_zone = var.GENOMENEXUS_EBS_VOLUME_AZ
  size              = 100
  type              = "gp3"
  snapshot_id       = "snap-0617b81fca0195df7"

  tags = {
    Name          = "gn-mongo-genie-mongodb"
    cdsi-app      = "genome-nexus"
    cdsi-team     = "data-engineering"
    cdsi-owner    = "lix2@mskcc.org"
    resource-name = "gn-mongo-genie-mongodb"
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "gn_mongo_genie_volume_id" {
  value = aws_ebs_volume.gn-mongo-genie-mongodb.id
}
