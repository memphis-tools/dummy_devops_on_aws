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

# Security Group for Wazuh Server
resource "aws_security_group" "wazuh_server_sg" {
  name        = "wazuh-server-security-group"
  description = "Allow SSH from laptop and Wazuh HTTP(S) only from default VPC"
  vpc_id      = data.aws_vpc.default.id

  # Ingress rules
  ingress {
    description = "SSH from my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.authorized_ip]
  }

  ingress {
  description = "Wazuh server, agent connection service (TCP) for default VPC"
    from_port   = 1514
    to_port     = 1514
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    description = "Wazuh server, agent enrollment service for default VPC"
    from_port   = 1515
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    description = "Wazuh server RESTful API for default VPC"
    from_port   = 55000
    to_port     = 55000
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

# EC2 instance running Wazuh
resource "aws_instance" "wazuh_server" {
  ami           = var.golden_image_id
  instance_type = "t3.medium"
  key_name      = var.aws_keypair_name
  vpc_security_group_ids = [aws_security_group.wazuh_server_sg.id]

  # Attach the IAM Instance Profile to the EC2 instance
  #iam_instance_profile     = aws_iam_instance_profile.wazuh_server_instance_profile.name
  iam_instance_profile = var.wazuh_server_instance_profile

  # Enforce IMDSv2 (IMDSv2 – newer than v1, requires a session token, mitigates some SSRF attacks and improves security.)
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  # Block device mapping for custom disk size (root disk size to 20GB)
  # Use General Purpose SSD (gp3) for better performance
  # Optionally delete the disk when the instance is terminated
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Install Wazuh Server
              sudo apt-get update -y
              # Wazuh server
              sudo apt-get install -y gnupg apt-transport-https

              # Install GPG key
              sudo bash -c "curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg"

              # Add the repository.
              echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee -a /etc/apt/sources.list.d/wazuh.list

              # Update packages informations
              sudo apt-get update -y

              # Wazuh server
              sudo apt-get -y install wazuh-manager filebeat

              # Set hostname
              sudo hostnamectl set-hostname ${var.wazuh_server_hostname}

              # Set timezone
              sudo timedatectl set-timezone ${var.stack_timezone}

              # Optionally update /etc/hosts to map the hostname to localhost
              sudo sed -i '/127.0.0.1/s/$/ ${var.wazuh_server_hostname}/' /etc/hosts

              EOF

  tags = {
    Name = "WAZUH-SERVER"
  }
}

output "wazuh_server_public_ip" {
  description = "Public IPv4 of the instance"
  value       = aws_instance.wazuh_server.public_ip
  depends_on = [aws_instance.wazuh_server]
}

output "wazuh_server_private_ip" {
  description = "Private IPv4 of the instance"
  value = aws_instance.wazuh_server.private_ip
  depends_on = [aws_instance.wazuh_server]
}
