variable "k8s_instance_profile" {
  description = "IAM K8S Instance Profile for EC2 instances"
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

variable "k8s_hostname" {
  type    = string
}

variable "stack_timezone" {
  type    = string
}

variable "ansible_username" {
  type    = string
  default = "devops"
}
