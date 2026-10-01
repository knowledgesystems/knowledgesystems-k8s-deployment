resource "aws_instance" "hermes_agent" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = "subnet-0e91c0e7119c7a136"
  associate_public_ip_address = false
  key_name                    = var.key_name
  user_data                   = file("${path.module}/bootstrap.sh")
  user_data_replace_on_change = true
  vpc_security_group_ids      = ["sg-03bc1bfbebc3b9651", "sg-07f9067f60b547b5a"]

  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }

  root_block_device {
    volume_size           = 40
    volume_type           = "gp3"
    encrypted             = true
    iops                  = 3000
    throughput            = 125
    delete_on_termination = false
    tags = {
      resource-name = "cbio-claw-dev-root"
      cdsi-app      = "cbio-claw"
      cdsi-team     = "data-visualization"
      cdsi-owner    = "koj2@mskcc.org"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

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

  lifecycle {
    prevent_destroy = true
  }
}

output "instance_id" {
  value = aws_instance.hermes_agent.id
}

output "private_ip" {
  value = aws_instance.hermes_agent.private_ip
}

output "root_volume_id" {
  value = aws_instance.hermes_agent.root_block_device[0].volume_id
}
