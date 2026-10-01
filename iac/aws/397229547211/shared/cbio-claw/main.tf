locals {
  tags = {
    Name             = "cbio-claw-dev"
    resource-name    = "cbio-claw-dev"
    cdsi-app         = "cbio-claw"
    cdsi-team        = "data-visualization"
    cdsi-owner       = "koj2@mskcc.org"
    application-tier = "tier-2"
    cost-center      = "50631"
    service-id       = "SNSVC0003845"
    env              = "dev"
    application      = "cbioportal-for-cancer-genomics"
    application-id   = "APM0001910"
    owner-email      = "SchultzN@mskcc.org"
  }
}

resource "aws_spot_instance_request" "hermes_agent" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = "subnet-0e91c0e7119c7a136"
  associate_public_ip_address = false
  key_name                    = var.key_name
  user_data                   = file("${path.module}/bootstrap.sh")
  user_data_replace_on_change = true
  vpc_security_group_ids      = ["sg-03bc1bfbebc3b9651", "sg-07f9067f60b547b5a"]

  spot_type                      = "persistent"
  instance_interruption_behavior = "stop"
  wait_for_fulfillment           = true

  root_block_device {
    volume_size           = 40
    volume_type           = "gp3"
    encrypted             = true
    iops                  = 3000
    throughput            = 125
    delete_on_termination = false
  }


  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

output "instance_id" {
  value = aws_spot_instance_request.hermes_agent.spot_instance_id
}

output "private_ip" {
  value = aws_spot_instance_request.hermes_agent.private_ip
}

output "root_volume_id" {
  value = aws_spot_instance_request.hermes_agent.root_block_device[0].volume_id
}

resource "aws_ec2_tag" "instance" {
  for_each    = local.tags
  resource_id = aws_spot_instance_request.hermes_agent.spot_instance_id
  key         = each.key
  value       = each.value
}

resource "aws_ec2_tag" "root_volume" {
  for_each = {
    resource-name = "cbio-claw-dev-root"
    cdsi-app      = "cbio-claw"
    cdsi-team     = "data-visualization"
    cdsi-owner    = "koj2@mskcc.org"
  }
  resource_id = aws_spot_instance_request.hermes_agent.root_block_device[0].volume_id
  key         = each.key
  value       = each.value
}
