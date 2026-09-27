variable "aws_account_id" {
  description = "The AWS account ID"
}

variable "golden_image_id" {
  type        = string
  description = "Base AMI ID to use for instances"
}

variable "authorized_ip" {
  type = string
}

variable "aws_keypair_name" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "aws_region" {
  description = "The AWS region"
}

variable "jenkins_hostname" {
  type    = string
  default = "aws-dummy-ops-jenkins.lab"
}

variable "tomcat_hostname" {
  type    = string
  default = "aws-dummy-ops-tomcat.lab"
}

variable "docker_hostname" {
  type    = string
  default = "aws-dummy-ops-docker.lab"
}

variable "ansible_hostname" {
  type    = string
  default = "aws-dummy-ops-ansible.lab"
}

variable "nginx_hostname" {
  type    = string
  default = "aws-dummy-ops-nginx.lab"
}

variable "wazuh_dashboard_hostname" {
  type    = string
  default = "aws-dummy-ops-wazuh-dashboard.lab"
}

variable "wazuh_indexer_hostname" {
  type    = string
  default = "aws-dummy-ops-wazuh-indexer.lab"
}

variable "wazuh_server_hostname" {
  type    = string
  default = "aws-dummy-ops-wazuh-server.lab"
}

variable "k8s_hostname" {
  type    = string
  default = "aws-dummy-ops-k8s.lab"
}

variable "stack_timezone" {
  type    = string
  default = "Europe/Paris"
}

variable "application_domain" {
  description = "Public application domain"
  type        = string
  default     = "app.crook-ops.dev"
}

variable "alb_name" {
  description = "Application Load Balancer name"
  type        = string
  default     = "crook-ops-alb"
}

variable "k8s_cluster_name" {
  description = "Existing eksctl EKS cluster name"
  type        = string
  default     = "dummy-ops-eks"
}
