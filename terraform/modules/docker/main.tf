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

# Security Group for
resource "aws_security_group" "docker_sg" {
  name        = "docker-security-group"
  description = "Allow SSH from laptop and Docker HTTP(S) only from default VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.authorized_ip]
  }

  ingress {
    description = "SSH from default VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    description = "Docker HTTP from default VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    description = "Docker HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker HTTPS from default VPC"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    description = "Docker HTTPS"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  description = "Wazuh, for agent communication, from default vpc"
  from_port   = 1514
  to_port     = 1514
  protocol    = "tcp"
  cidr_blocks = [data.aws_vpc.default.cidr_block]
}

ingress {
  description = "Wazuh, for enrollment via automatic agent request, from default vpc"
  from_port   = 1515
  to_port     = 1515
  protocol    = "tcp"
  cidr_blocks = [data.aws_vpc.default.cidr_block]
}

ingress {
  description = "Wazuh, for enrollment via Wazuh server API, from default vpc"
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


# EC2 instance running Docker
resource "aws_instance" "docker" {
  ami           = var.golden_image_id
  instance_type = "t2.micro"
  key_name      = var.aws_keypair_name
  vpc_security_group_ids = [aws_security_group.docker_sg.id]

  # Attach the IAM Instance Profile to the EC2 instance
  #iam_instance_profile     = aws_iam_instance_profile.docker_instance_profile.name
  iam_instance_profile = var.docker_instance_profile

  # Enforce IMDSv2 (IMDSv2 – newer than v1, requires a session token, mitigates some SSRF attacks and improves security.)
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  # Attach EBS volumes
  # Default disk size for t2.micro is 8 gb
  root_block_device {
    volume_size = 8
  }

  # /home
  ebs_block_device {
    device_name = "/dev/sdf"  # Linux will see it as /dev/xvdf
    volume_size = 1  # GB
    delete_on_termination = true
  }

  # /opt/docker_projects
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 5
    delete_on_termination = true
  }

  # Copy jenkins user's public key to instance
  provisioner "file" {
    source      = "../ephemeral-keys/jenkins_github.pub"
    destination = "/tmp/jenkins_github.pub"

    connection {
      host        = self.public_ip
      user        = "admin"
      private_key = file(var.private_key_path)
    }
  }

  # Copy ansible user's public key to instance
    provisioner "file" {
      source      = "../ephemeral-keys/ansible_docker.pub"
      destination = "/tmp/ansible_docker.pub"

      connection {
        host        = self.public_ip
        user        = "admin"
        private_key = file(var.private_key_path)
      }
    }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              # Format and mount EBS volumes
              sudo mkfs.ext4 /dev/xvdf
              sudo mkfs.ext4 /dev/xvdg
              sudo mkdir -p /home
              sudo mkdir -p /opt/docker_projects

              # Mount the new volume temporarily
              sudo mount /dev/xvdf /mnt
              # Copy existing home contents
              sudo rsync -a /home/ /mnt/
              # Unmount, then mount permanently
              sudo umount /mnt

              sudo mount /dev/xvdf /home
              sudo mount /dev/xvdg /opt/docker_projects
              echo '/dev/xvdf /home ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
              echo '/dev/xvdg /opt/docker_projects ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

              sudo apt-get update -y
              # Add Docker's official GPG key:
              sudo apt-get install -y ca-certificates curl
              sudo install -m 0755 -d /etc/apt/keyrings
              sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
              sudo chmod a+r /etc/apt/keyrings/docker.asc

              # Add the repository to Apt sources:
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

              sudo apt-get update -y
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              docker --version
              docker compose version

              sudo groupadd devops_users
              sudo useradd -m ${var.docker_username} -s /bin/bash -g devops_users
              sudo usermod -aG docker ${var.docker_username}
              sudo mkdir /home/${var.docker_username}/.ssh
              cat /home/admin/.ssh/authorized_keys > /home/${var.docker_username}/.ssh/authorized_keys
              cat /tmp/jenkins_github.pub >> /home/${var.docker_username}/.ssh/authorized_keys
              cat /tmp/ansible_docker.pub >> /home/${var.docker_username}/.ssh/authorized_keys
              sudo chmod 0700 /home/${var.docker_username}
              chown -R ${var.docker_username}: /home/${var.docker_username}

              # Set hostname
              sudo hostnamectl set-hostname ${var.docker_hostname}

              # Optionally update /etc/hosts to map the hostname to localhost
              sudo sed -i '/127.0.0.1/s/$/ ${var.docker_hostname}/' /etc/hosts

              # Set timezone
              sudo timedatectl set-timezone ${var.stack_timezone}
              EOF

  tags = {
    Name = "DOCKER"
  }
}

output "docker_public_ip" {
  description = "Public IPv4 of the instance"
  value       = aws_instance.docker.public_ip
  depends_on = [aws_instance.docker]
}

output "docker_private_ip" {
  description = "Private IPv4 of the instance"
  value = aws_instance.docker.private_ip
  depends_on = [aws_instance.docker]
}

output "docker_instance_id" {
  value = aws_instance.docker.id
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}
