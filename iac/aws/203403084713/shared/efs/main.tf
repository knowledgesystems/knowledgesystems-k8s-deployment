resource "aws_efs_file_system" "efs-cbioagent" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "efs-cbioagent"
  }
}

resource "aws_efs_mount_target" "efs-mount-targets-cbioagent" {
  count          = length(var.SUBNET_IDS)
  file_system_id = aws_efs_file_system.efs-cbioagent.id
  subnet_id      = var.SUBNET_IDS[count.index]
}