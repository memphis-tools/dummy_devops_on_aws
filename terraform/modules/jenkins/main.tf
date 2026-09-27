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
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-security-group"
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

# EC2 instance running Jenkins
resource "aws_instance" "jenkins" {
  ami           = var.golden_image_id
  instance_type = "t2.small"
  key_name      = var.aws_keypair_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # Attach the IAM Instance Profile to the EC2 instance
  #iam_instance_profile     = aws_iam_instance_profile.jenkins_instance_profile.name
  iam_instance_profile = var.jenkins_instance_profile

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

  # Copy jenkins user's private key to instance
  provisioner "file" {
    source      = "../ephemeral-keys/jenkins_github"
    destination = "/tmp/jenkins_github"

    connection {
      host        = self.public_ip
      user        = "admin"
      private_key = file(var.private_key_path)
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              set -x

              # Septembre 22th (2026): "serious bugs of ca-certificates-java" .
              # We are in a POC lab. Either we use Debian12, either we uninstall the apt-listbugs which cancel apt in cas of bug
              sudo apt-get update -y
              sudo apt-get remove -y apt-listbugs
              sudo apt modernize-sources -y
              sudo apt install -y fontconfig default-jdk curl ssh-askpass jq python3-boto3 git maven
              sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
              echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              # Wait for apt lock to be released if held by another process
              while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
                echo "Waiting for apt lock to be released..."
                sleep 2
              done
              sudo apt update -y
              sudo apt install -y jenkins
              sudo mkdir /var/lib/jenkins/temp
              sudo mkdir /var/lib/jenkins/.ssh
              sudo cp /tmp/jenkins_github.pub /var/lib/jenkins/.ssh/jenkins_github.pub
              sudo cp /tmp/jenkins_github /var/lib/jenkins/.ssh/jenkins_github
              sudo touch /var/lib/jenkins/.bashrc
              echo "M2='/usr/share/maven/bin'" | sudo tee -a /var/lib/jenkins/.bashrc
              echo "M2_HOME='/usr/share/maven'" | sudo tee -a /var/lib/jenkins/.bashrc
              echo "JAVA_HOME='/usr/lib/jvm/java-21-openjdk-amd64/'" | sudo tee -a /var/lib/jenkins/.bashrc
              sudo chmod 0600 /var/lib/jenkins/.ssh/jenkins_github
              sudo chmod 0700 /var/lib/jenkins/.ssh
              sudo chmod 0750 /var/lib/jenkins/temp
              sudo chown -R jenkins:jenkins /var/lib/jenkins/

              # Set hostname
              sudo hostnamectl set-hostname ${var.jenkins_hostname}

              # Optionally update /etc/hosts to map the hostname to localhost
              sudo sed -i '/127.0.0.1/s/$/ ${var.jenkins_hostname}/' /etc/hosts

              # Set timezone
              sudo timedatectl set-timezone ${var.stack_timezone}
              EOF
  tags = {
    Name = "JENKINS"
  }
}

output "jenkins_public_ip" {
  description = "Public IPv4 of the instance"
  value       = aws_instance.jenkins.public_ip
  depends_on = [aws_instance.jenkins]
}

output "jenkins_private_ip" {
  description = "Private IPv4 of the instance"
  value = aws_instance.jenkins.private_ip
  depends_on = [aws_instance.jenkins]
}
