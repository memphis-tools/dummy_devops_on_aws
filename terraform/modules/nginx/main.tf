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
resource "aws_security_group" "nginx_sg" {
  name        = "nginx-security-group"
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
    description = "HTTP from my laptop"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.authorized_ip]
  }

  ingress {
    description = "HTTP from default VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  # Ingress rule for GitHub Public IP Ranges
  # ip can be retrieve through: curl -s https://api.github.com/meta | jq '.hooks'
  ingress {
    description = "HTTPS from GitHub"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "192.30.252.0/22",
      "185.199.108.0/22",
      "140.82.112.0/20",
      "143.55.64.0/20"
    ]
  }

  ingress {
    description = "HTTPS from my laptop"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.authorized_ip]
  }

  ingress {
    description = "HTTPS from default VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    description = "HTTPS from default VPC, for jenkins hook"
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

# EC2 instance running Nginx
resource "aws_instance" "nginx" {
  ami           = var.golden_image_id
  instance_type = "t2.micro"
  key_name      = var.aws_keypair_name
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  # Attach the IAM Instance Profile to the EC2 instance
  #iam_instance_profile     = aws_iam_instance_profile.nginx_instance_profile.name
  iam_instance_profile = var.nginx_instance_profile

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
    volume_size = 1
    delete_on_termination = true
  }

  # /var/log/nginx
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 2
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
              sudo mkdir -p /var/log/nginx

              # Mount the new volume temporarily
              sudo mount /dev/xvdf /mnt
              # Copy existing home contents
              sudo rsync -a /home/ /mnt/
              # Unmount, then mount permanently
              sudo umount /mnt

              sudo mount /dev/xvdf /home
              sudo mount /dev/xvdg /var/log/nginx
              echo '/dev/xvdf /home ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
              echo '/dev/xvdg /var/log/nginx ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

              sudo apt-get update -y
              sudo apt-get install -y nginx ca-certificates curl ssh-askpass jq python3-boto3
              sudo groupadd devops_users
              sudo useradd -m ${var.nginx_username} -s /bin/bash -g devops_users
              sudo mkdir /home/${var.nginx_username}/.ssh
              sudo cat /home/admin/.ssh/authorized_keys > /home/${var.nginx_username}/.ssh/authorized_keys
              sudo cat /tmp/jenkins_github.pub >> /home/${var.nginx_username}/.ssh/authorized_keys
              sudo cat /tmp/ansible_docker.pub >> /home/${var.nginx_username}/.ssh/authorized_keys
              sudo chmod 0700 /home/${var.nginx_username}/.ssh/
              sudo chown -R ${var.nginx_username}: /home/${var.nginx_username}

              # Set hostname
              sudo hostnamectl set-hostname ${var.nginx_hostname}

              # Optionally update /etc/hosts to map the hostname to localhost
              sudo sed -i '/127.0.0.1/s/$/ ${var.nginx_hostname}/' /etc/hosts

              # Set timezone
              sudo timedatectl set-timezone ${var.stack_timezone}
              EOF

  tags = {
    Name = "NGINX"
  }
}

output "nginx_public_ip" {
  description = "Public IPv4 of the instance"
  value       = aws_instance.nginx.public_ip
  depends_on = [aws_instance.nginx]
}

output "nginx_private_ip" {
  description = "Private IPv4 of the instance"
  value = aws_instance.nginx.private_ip
  depends_on = [aws_instance.nginx]
}
