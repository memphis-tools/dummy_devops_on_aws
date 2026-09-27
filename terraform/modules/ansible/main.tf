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

# Security Group for Ansible
resource "aws_security_group" "ansible_sg" {
  name        = "ansible-security-group"
  description = "Allow SSH from laptop and Ansible HTTP(S) only from default VPC"
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

# EC2 instance running Ansible
resource "aws_instance" "ansible" {
  ami           = var.golden_image_id
  instance_type = "t2.micro"
  key_name      = var.aws_keypair_name
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]

  # Attach the IAM Instance Profile to the EC2 instance
  #iam_instance_profile     = aws_iam_instance_profile.ansible_instance_profile.name
  iam_instance_profile = var.ansible_instance_profile

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

  # home
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

  # Copy ansible user's private key to instance
    provisioner "file" {
      source      = "../ephemeral-keys/ansible_docker"
      destination = "/tmp/ansible_docker"

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
                echo '/dev/xvdb /opt/docker_projects ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

                # Wait for apt lock to be released if held by another process
                while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
                  echo "Waiting for apt lock to be released..."
                  sleep 2
                done

                sudo apt-get update -y
                sudo apt-get install -y ansible sshpass
                ansible --version
                sudo ansible-galaxy collection install community.docker

                # Add Docker's official GPG key
                sudo apt-get install -y ca-certificates curl wget gnupg
                sudo install -m 0755 -d /etc/apt/keyrings
                sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
                sudo chmod a+r /etc/apt/keyrings/docker.asc

                # Add the Docker repository to Apt sources
                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
                  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                # Add the GitHub CLI repository
                out=$(mktemp)
                wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg
                cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
                sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
                sudo mkdir -p -m 755 /etc/apt/sources.list.d
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

                # We are in a POC lab
                sudo apt-get update -y
                sudo apt-get remove -y apt-listbugs
                sudo apt modernize-sources -y
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin ssh-askpass jq python3-boto3 gh

                gh --version

                sudo groupadd devops_users
                sudo useradd -m ${var.ansible_username} -s /bin/bash -g devops_users
                sudo usermod -aG docker ${var.ansible_username}
                sudo mkdir /home/${var.ansible_username}/.ssh
                sudo cat /home/admin/.ssh/authorized_keys > /home/${var.ansible_username}/.ssh/authorized_keys
                sudo cat /tmp/jenkins_github.pub >> /home/${var.ansible_username}/.ssh/authorized_keys
                sudo cat /tmp/ansible_docker.pub >> /home/${var.ansible_username}/.ssh/authorized_keys
                sudo cp /tmp/ansible_docker.pub /home/${var.ansible_username}/.ssh/
                sudo cp /tmp/ansible_docker /home/${var.ansible_username}/.ssh/
                sudo chmod 0700 /home/${var.ansible_username}/.ssh/
                sudo chmod 0600 /home/${var.ansible_username}/.ssh/ansible_docker
                sudo chown -R ${var.ansible_username}: /home/${var.ansible_username}
                sudo chown -R ${var.ansible_username}: /opt/docker_projects

                # Set hostname
                sudo hostnamectl set-hostname ${var.ansible_hostname}

                # Optionally update /etc/hosts to map the hostname to localhost
                sudo sed -i '/127.0.0.1/s/$/ ${var.ansible_hostname}/' /etc/hosts

                # Set timezone
                sudo timedatectl set-timezone ${var.stack_timezone}
                EOF
  
  tags = {
    Name = "ANSIBLE"
  }
}

output "ansible_public_ip" {
  description = "Public IPv4 of the instance"
  value       = aws_instance.ansible.public_ip
  depends_on = [aws_instance.ansible]
}

output "ansible_private_ip" {
  description = "Private IPv4 of the instance"
  value = aws_instance.ansible.private_ip
  depends_on = [aws_instance.ansible]
}
