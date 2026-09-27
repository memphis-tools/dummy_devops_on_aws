variable "jenkins_instance_profile" {
  description = "IAM Jenkins Instance Profile for EC2 instances"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "authorized_ip" {
  type    = string
}

variable "aws_keypair_name" {
  type    = string
}

variable "private_key_path" {
  type = string
}

variable "jenkins_hostname" {
  type    = string
}

variable "jenkins_ssh_passphrase" {
  type    = string
  default = "@pplepie94"
}

variable "stack_timezone" {
  type    = string
}
