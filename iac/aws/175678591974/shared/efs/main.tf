data "aws_vpc" "oncokb-research-vpc" {
  id = var.VPC_ID
}

resource "aws_security_group" "oncokb-research-efs-sg" {
  name        = "oncokb-research-efs-sg"
  description = "Security group to allow traffic from cluster vpc to efs"
  vpc_id      = var.VPC_ID

  tags = {
    Name = "oncokb-research-efs-sg"
  }
}

# Rules to allow  NFS traffic between VPC and EFS
resource "aws_vpc_security_group_ingress_rule" "oncokb-research-efs-ingress" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.oncokb-research-efs-sg.id
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = data.aws_vpc.oncokb-research-vpc.cidr_block
  description       = "Security group rule to allow traffic from cluster vpc to efs"

  tags = {
    Name = "EFS NFS Ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "oncokb-research-efs-egress" {
  ip_protocol       = -1
  security_group_id = aws_security_group.oncokb-research-efs-sg.id
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_efs_file_system" "oncokb-research-efs" {
  performance_mode = "generalPurpose"
  encrypted = false

  tags = {
    Name = "oncokb-research-efs"
  }
}

resource "aws_efs_mount_target" "oncokb-research-efs-mount-targets" {
  count           = length(var.SUBNET_IDS)
  file_system_id  = aws_efs_file_system.oncokb-research-efs.id
  subnet_id       = var.SUBNET_IDS[count.index]
  security_groups = [aws_security_group.oncokb-research-efs-sg.id]
}