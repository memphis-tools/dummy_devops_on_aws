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
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Allow SSH from laptop HTTP(S) only from default VPC"
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
    description = "HTTPS from default VPC"
    from_port   = 8443
    to_port     = 8443
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

# EC2 instance running K8S
resource "aws_instance" "k8s" {
  ami           = var.golden_image_id
  instance_type = "t2.small"
  key_name      = var.aws_keypair_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  # Attach the IAM Instance Profile to the EC2 instance
  #iam_instance_profile     = aws_iam_instance_profile.k8s_instance_profile.name
  iam_instance_profile = var.k8s_instance_profile


  # Enforce IMDSv2 (IMDSv2 – newer than v1, requires a session token, mitigates some SSRF attacks and improves security.)
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
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
              set -x
              sudo apt-get update -y
              sudo apt install -y kubectl kubecolor

              # install eksctl using docs.aws.* instructions
              ARCH=amd64
              PLATFORM=$(uname -s)_$ARCH
              curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
              # (Optional) Verify checksum
              curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
              tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
              sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl
              # End from docs.aws.*

              ## Wait for apt lock to be released if held by another process
              #while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
              #  echo "Waiting for apt lock to be released..."
              #  sleep 2
              #done
              #sudo apt update -y
              sudo groupadd devops_users
              sudo useradd -m ${var.ansible_username} -s /bin/bash -g devops_users
              sudo usermod -aG docker ${var.ansible_username}
              sudo mkdir /home/${var.ansible_username}/.ssh
              sudo cat /home/admin/.ssh/authorized_keys > /home/${var.ansible_username}/.ssh/authorized_keys
              sudo cat /tmp/jenkins_github.pub >> /home/${var.ansible_username}/.ssh/authorized_keys
              sudo cat /tmp/ansible_docker.pub >> /home/${var.ansible_username}/.ssh/authorized_keys
              sudo chmod 0700 /home/${var.ansible_username}
              sudo chown -R ${var.ansible_username}: /home/${var.ansible_username}/
              echo 'devops ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers

              # Set hostname
              sudo hostnamectl set-hostname ${var.k8s_hostname}

              # Optionally update /etc/hosts to map the hostname to localhost
              sudo sed -i '/127.0.0.1/s/$/ ${var.k8s_hostname}/' /etc/hosts

              # Set timezone
              sudo timedatectl set-timezone ${var.stack_timezone}
              EOF
  tags = {
    Name = "K8S"
  }
}

output "k8s_public_ip" {
  description = "Public IPv4 of the instance"
  value       = aws_instance.k8s.public_ip
  depends_on = [aws_instance.k8s]
}

output "k8s_private_ip" {
  description = "Private IPv4 of the instance"
  value = aws_instance.k8s.private_ip
  depends_on = [aws_instance.k8s]
}
