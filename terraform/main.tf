provider "aws" {
  region = var.aws_region
}

module "roles_and_policies" {
  source         = "./roles_and_policies"
  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id
}

module "jenkins" {
  source                   = "./modules/jenkins"
  aws_region               = var.aws_region
  aws_account_id           = var.aws_account_id
  authorized_ip            = var.authorized_ip
  aws_keypair_name         = var.aws_keypair_name
  private_key_path         = var.private_key_path
  jenkins_hostname         = var.jenkins_hostname
  stack_timezone           = var.stack_timezone
  golden_image_id          = var.golden_image_id
  jenkins_instance_profile = module.roles_and_policies.jenkins_instance_profile
}

module "tomcat" {
  source                  = "./modules/tomcat"
  aws_region              = var.aws_region
  aws_account_id          = var.aws_account_id
  authorized_ip           = var.authorized_ip
  aws_keypair_name        = var.aws_keypair_name
  private_key_path        = var.private_key_path
  tomcat_hostname         = var.tomcat_hostname
  stack_timezone          = var.stack_timezone
  golden_image_id         = var.golden_image_id
  tomcat_instance_profile = module.roles_and_policies.tomcat_instance_profile
}

module "docker" {
  source                  = "./modules/docker"
  aws_region              = var.aws_region
  aws_account_id          = var.aws_account_id
  authorized_ip           = var.authorized_ip
  aws_keypair_name        = var.aws_keypair_name
  private_key_path        = var.private_key_path
  docker_hostname         = var.docker_hostname
  stack_timezone          = var.stack_timezone
  golden_image_id         = var.golden_image_id
  docker_instance_profile = module.roles_and_policies.docker_instance_profile
}

module "ansible" {
  source                   = "./modules/ansible"
  aws_region               = var.aws_region
  aws_account_id           = var.aws_account_id
  authorized_ip            = var.authorized_ip
  aws_keypair_name         = var.aws_keypair_name
  private_key_path         = var.private_key_path
  ansible_hostname         = var.ansible_hostname
  stack_timezone           = var.stack_timezone
  golden_image_id          = var.golden_image_id
  ansible_instance_profile = module.roles_and_policies.ansible_instance_profile
}

module "nginx" {
  source                 = "./modules/nginx"
  aws_region             = var.aws_region
  aws_account_id         = var.aws_account_id
  authorized_ip          = var.authorized_ip
  aws_keypair_name       = var.aws_keypair_name
  private_key_path       = var.private_key_path
  nginx_hostname         = var.nginx_hostname
  stack_timezone         = var.stack_timezone
  golden_image_id        = var.golden_image_id
  nginx_instance_profile = module.roles_and_policies.nginx_instance_profile
}

module "wazuh_dashboard" {
  source                           = "./modules/wazuh_dashboard"
  aws_region                       = var.aws_region
  aws_account_id                   = var.aws_account_id
  authorized_ip                    = var.authorized_ip
  aws_keypair_name                 = var.aws_keypair_name
  private_key_path                 = var.private_key_path
  wazuh_dashboard_hostname         = var.wazuh_dashboard_hostname
  stack_timezone                   = var.stack_timezone
  golden_image_id                  = var.golden_image_id
  wazuh_dashboard_instance_profile = module.roles_and_policies.wazuh_dashboard_instance_profile
}

module "wazuh_indexer" {
  source                         = "./modules/wazuh_indexer"
  aws_region                     = var.aws_region
  aws_account_id                 = var.aws_account_id
  authorized_ip                  = var.authorized_ip
  aws_keypair_name               = var.aws_keypair_name
  private_key_path               = var.private_key_path
  wazuh_indexer_hostname         = var.wazuh_indexer_hostname
  stack_timezone                 = var.stack_timezone
  golden_image_id                = var.golden_image_id
  wazuh_indexer_instance_profile = module.roles_and_policies.wazuh_indexer_instance_profile
}

module "wazuh_server" {
  source                        = "./modules/wazuh_server"
  aws_region                    = var.aws_region
  aws_account_id                = var.aws_account_id
  authorized_ip                 = var.authorized_ip
  aws_keypair_name              = var.aws_keypair_name
  private_key_path              = var.private_key_path
  wazuh_server_hostname         = var.wazuh_server_hostname
  stack_timezone                = var.stack_timezone
  golden_image_id               = var.golden_image_id
  wazuh_server_instance_profile = module.roles_and_policies.wazuh_server_instance_profile
}

module "k8s" {
  source               = "./modules/k8s"
  aws_region           = var.aws_region
  aws_account_id       = var.aws_account_id
  authorized_ip        = var.authorized_ip
  aws_keypair_name     = var.aws_keypair_name
  private_key_path     = var.private_key_path
  k8s_hostname         = var.k8s_hostname
  stack_timezone       = var.stack_timezone
  golden_image_id      = var.golden_image_id
  k8s_instance_profile = module.roles_and_policies.k8s_instance_profile
}


output "jenkins_public_ip" {
  description = "Public IPv4 of Jenkins instance"
  value       = module.jenkins.jenkins_public_ip
}

output "jenkins_private_ip" {
  description = "Private IPv4 of Jenkins instance"
  value       = module.jenkins.jenkins_private_ip
}

output "tomcat_public_ip" {
  description = "Public IPv4 of Tomcat instance"
  value       = module.tomcat.tomcat_public_ip
}

output "tomcat_private_ip" {
  description = "Private IPv4 of Tomcat instance"
  value       = module.tomcat.tomcat_private_ip
}

output "docker_public_ip" {
  description = "Public IPv4 of Docker instance"
  value       = module.docker.docker_public_ip
}

output "docker_private_ip" {
  description = "Private IPv4 of Docker instance"
  value       = module.docker.docker_private_ip
}

output "ansible_public_ip" {
  description = "Public IPv4 of Ansible instance"
  value       = module.ansible.ansible_public_ip
}

output "ansible_private_ip" {
  description = "Private IPv4 of Ansible instance"
  value       = module.ansible.ansible_private_ip
}

output "nginx_public_ip" {
  description = "Public IPv4 of nginx instance"
  value       = module.nginx.nginx_public_ip
}

output "nginx_private_ip" {
  description = "Private IPv4 of Nginx instance"
  value       = module.nginx.nginx_private_ip
}

output "wazuh_dashboard_public_ip" {
  description = "Public IPv4 of wazuh_dashboard instance"
  value       = module.wazuh_dashboard.wazuh_dashboard_public_ip
}

output "wazuh_dashboard_private_ip" {
  description = "Private IPv4 of wazuh_dashboard instance"
  value       = module.wazuh_dashboard.wazuh_dashboard_private_ip
}

output "wazuh_indexer_public_ip" {
  description = "Public IPv4 of wazuh_indexer instance"
  value       = module.wazuh_indexer.wazuh_indexer_public_ip
}

output "wazuh_indexer_private_ip" {
  description = "Private IPv4 of wazuh_indexer instance"
  value       = module.wazuh_indexer.wazuh_indexer_private_ip
}

output "wazuh_server_public_ip" {
  description = "Public IPv4 of wazuh_server instance"
  value       = module.wazuh_server.wazuh_server_public_ip
}

output "wazuh_server_private_ip" {
  description = "Private IPv4 of wazuh_server instance"
  value       = module.wazuh_server.wazuh_server_private_ip
}

output "k8s_public_ip" {
  description = "Public IPv4 of k8s instance"
  value       = module.k8s.k8s_public_ip
}

output "k8s_private_ip" {
  description = "Private IPv4 of k8s instance"
  value       = module.k8s.k8s_private_ip
}

output "tomcat_instance_id" {
  value = module.tomcat.tomcat_instance_id
}

output "docker_instance_id" {
  value = module.docker.docker_instance_id
}
