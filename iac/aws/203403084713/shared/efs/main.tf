data "aws_vpc" "cbioportal-prod-vpc" {
  id = var.VPC_ID
}

resource "aws_security_group" "sg-cbioagent" {
  name        = "cBioAgent-EFS"
  description = "Security group to allow traffic from cluster vpc to efs"
  vpc_id      = var.VPC_ID

  tags = {
    Name = "cBioAgent-EFS"
  }
}

# Rules to allow  NFS traffic between VPC and EFS
resource "aws_vpc_security_group_ingress_rule" "efs-cbioagent-ingress" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.sg-cbioagent.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = data.aws_vpc.cbioportal-prod-vpc.cidr_block
  description       = "Security group rule to allow traffic from cluster vpc to efs"

  tags = {
    Name = "EFS NFS Ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "efs-cbioagent-egress" {
  ip_protocol       = -1
  security_group_id = aws_security_group.sg-cbioagent.id
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_efs_file_system" "efs-cbioagent" {
  performance_mode = "generalPurpose"
  encrypted = false

  tags = {
    Name = "efs-cbioagent"
  }
}

resource "aws_efs_mount_target" "efs-mount-targets-cbioagent" {
  count           = length(var.SUBNET_IDS)
  file_system_id  = aws_efs_file_system.efs-cbioagent.id
  subnet_id       = var.SUBNET_IDS[count.index]
  security_groups = [aws_security_group.sg-cbioagent.id]
}