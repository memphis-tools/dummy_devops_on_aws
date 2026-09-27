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

# Security Group for Tomcat
resource "aws_security_group" "tomcat_sg" {
  name        = "tomcat-security-group"
  description = "Allow SSH from laptop and Tomcat HTTP(S) only from default VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.authorized_ip]
  }

  ingress {
    description = "Tomcat HTTP from default VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    description = "Tomcat HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Tomcat HTTPS from default VPC"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    description = "Tomcat HTTPS"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance running Tomcat
resource "aws_instance" "tomcat" {
  ami           = var.golden_image_id
  instance_type = "t2.micro"
  key_name      = var.aws_keypair_name
  vpc_security_group_ids = [aws_security_group.tomcat_sg.id]

  # Attach the IAM Instance Profile to the EC2 instance
  #iam_instance_profile     = aws_iam_instance_profile.tomcat_instance_profile.name
  iam_instance_profile = var.tomcat_instance_profile

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

  # /opt
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 2
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              # Format and mount EBS volumes
              sudo mkfs.ext4 /dev/xvdf
              sudo mkfs.ext4 /dev/xvdg
              sudo mkdir -p /home

              # Mount the new volume temporarily
              sudo mount /dev/xvdf /mnt
              # Copy existing home contents
              sudo rsync -a /home/ /mnt/
              # Unmount, then mount permanently
              sudo umount /mnt

              sudo mount /dev/xvdf /home
              sudo mount /dev/xvdg /opt
              echo '/dev/xvdf /home ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
              echo '/dev/xvdg /opt ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

              # Septembre 22th (2026): "serious bugs of ca-certificates-java" .
              # We are in a POC lab. Either we use Debian12, either we uninstall the apt-listbugs which cancel apt in cas of bug
              sudo apt-get update -y
              sudo apt-get remove -y apt-listbugs

              # Install Java
              sudo apt-get update -y
              sudo apt-get install -y default-jre
              java -version

              # Get and deploy tomcat
              BASE_URL="https://dlcdn.apache.org/tomcat/tomcat-11"
              VERSION=$(curl -fsSL "$BASE_URL/" \
                | grep -oE 'v11\.[0-9]+\.[0-9]+/' \
                | sed 's|/||' \
                | sort -V \
                | tail -1)
              TOMCAT_VERSION="$${VERSION#v}"
              TOMCAT_URL="$BASE_URL/$VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"

              cd /opt
              wget "$TOMCAT_URL"
              tar -xzf apache-tomcat-$TOMCAT_VERSION.tar.gz
              rm apache-tomcat-$TOMCAT_VERSION.tar.gz
              ln -s /opt/apache-tomcat-$TOMCAT_VERSION /opt/tomcat
              # Create tomcat user
              sudo groupadd tomcat
              sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
              sudo chown -R tomcat: /opt/tomcat /opt/apache-tomcat-$TOMCAT_VERSION
              ln -s /opt/tomcat/bin/startup.sh /usr/local/bin/start_tomcat
              ln -s /opt/tomcat/bin/shutdown.sh /usr/local/bin/stop_tomcat

              # Set hostname
              sudo hostnamectl set-hostname ${var.tomcat_hostname}

              # Optionally update /etc/hosts to map the hostname to localhost
              sudo sed -i '/127.0.0.1/s/$/ ${var.tomcat_hostname}/' /etc/hosts

              # Set timezone
              sudo timedatectl set-timezone ${var.stack_timezone}
              EOF

  tags = {
    Name = "TOMCAT"
  }
}

output "tomcat_public_ip" {
  description = "Public IPv4 of the instance"
  value       = aws_instance.tomcat.public_ip
  depends_on = [aws_instance.tomcat]
}

output "tomcat_private_ip" {
  description = "Private IPv4 of the instance"
  value = aws_instance.tomcat.private_ip
  depends_on = [aws_instance.tomcat]
}

output "tomcat_instance_id" {
  value = aws_instance.tomcat.id
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}
