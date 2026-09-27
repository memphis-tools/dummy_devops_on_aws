variable "golden_image_id" {
  description = "The AMI ID for the project's golden image"
  type        = string
}

provider "aws" {
  region = "eu-west-3"
}

# The default VPC CIDR block
data "aws_vpc" "default" {
  default = true
}

# Security Group for Wazuh Dashboard
resource "aws_security_group" "wazuh_dashboard_sg" {
  name        = "wazuh-dashboard-security-group"
  description = "Allow SSH from laptop and Wazuh HTTP(S) only from default VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.authorized_ip]
  }

  ingress {
    description = "Wazuh dashboard  HTTPS from my laptop"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.authorized_ip]
  }

  ingress {
    description = "Wazuh dashboard  HTTPS from my default vpc"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance running Wazuh Dashboard
resource "aws_instance" "wazuh_dashboard" {
  ami           = var.golden_image_id
  instance_type = "t3.small"
  key_name      = var.aws_keypair_name
  vpc_security_group_ids = [aws_security_group.wazuh_dashboard_sg.id]

  # Attach the IAM Instance Profile to the EC2 instance
  #iam_instance_profile     = aws_iam_instance_profile.wazuh_dashboard_instance_profile.name
  iam_instance_profile = var.wazuh_dashboard_instance_profile

  # Enforce IMDSv2 (IMDSv2 – newer than v1, requires a session token, mitigates some SSRF attacks and improves security.)
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Install Wazuh Dashboard
              sudo apt-get update -y
              sudo apt-get install -y tar curl libcap2-bin
              #sudo apt-get install -y debhelper

              # Install GPG key
              sudo bash -c "curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg"

              # Add the repository.
              echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee -a /etc/apt/sources.list.d/wazuh.list

              # Update packages informations
              sudo apt-get update -y

              # Wazuh dashboard
              sudo apt-get -y install wazuh-dashboard

              # Set hostname
              sudo hostnamectl set-hostname ${var.wazuh_dashboard_hostname}

              # Set timezone
              sudo timedatectl set-timezone ${var.stack_timezone}

              # Optionally update /etc/hosts to map the hostname to localhost
              sudo sed -i '/127.0.0.1/s/$/ ${var.wazuh_dashboard_hostname}/' /etc/hosts
              EOF

  tags = {
    Name = "WAZUH-DASHBOARD"
  }
}

output "wazuh_dashboard_public_ip" {
  description = "Public IPv4 of the instance"
  value       = aws_instance.wazuh_dashboard.public_ip
  depends_on = [aws_instance.wazuh_dashboard]
}

output "wazuh_dashboard_private_ip" {
  description = "Private IPv4 of the instance"
  value = aws_instance.wazuh_dashboard.private_ip
  depends_on = [aws_instance.wazuh_dashboard]
}
