#!/bin/bash

set -eu

ROLENAME1="jenkins_secret_manager_role"
ROLENAME2="tomcat_secret_manager_role"
ROLENAME3="ansible_secret_manager_role"
ROLENAME4="docker_secret_manager_role"
ROLENAME5="nginx_secret_manager_role"

echo "[+] Listing AWS roles in region $AWS_REGION"
aws iam list-roles --region $AWS_REGION --query 'Roles[*].RoleName'

echo "[+] Listing attached role policies for role $ROLENAME1"
aws iam list-attached-role-policies --role-name $ROLENAME1

echo "[+] Listing role policies for role $ROLENAME1"
aws iam list-role-policies --role-name $ROLENAME1

echo "[+] Listing attached role policies for role $ROLENAME2"
aws iam list-attached-role-policies --role-name $ROLENAME2

echo "[+] Listing role policies for role $ROLENAME2"
aws iam list-role-policies --role-name $ROLENAME2

echo "[+] Listing attached role policies for role $ROLENAME3"
aws iam list-attached-role-policies --role-name $ROLENAME3

echo "[+] Listing role policies for role $ROLENAME3"
aws iam list-role-policies --role-name $ROLENAME3

echo "[+] Listing attached role policies for role $ROLENAME4"
aws iam list-attached-role-policies --role-name $ROLENAME4

echo "[+] Listing role policies for role $ROLENAME4"
aws iam list-role-policies --role-name $ROLENAME4

echo "[+] Listing attached role policies for role $ROLENAME5"
aws iam list-attached-role-policies --role-name $ROLENAME5

echo "[+] Listing role policies for role $ROLENAME5"
aws iam list-role-policies --role-name $ROLENAME5
