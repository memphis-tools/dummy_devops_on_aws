#!/bin/bash

echo "=========================================="
echo "[+] STEP 1: Delete Customer-Managed Policies"
echo "=========================================="
for SERVICE in jenkins ansible docker tomcat nginx wazuh_dashboard wazuh_indexer wazuh_server k8s; do
    POLICY_ARN="arn:aws:iam::441520528080:policy/${SERVICE}_secret_manager_role_policy"

    echo "[${SERVICE}] Checking policy existence..."

    if aws iam get-policy --policy-arn "$POLICY_ARN" > /dev/null 2>&1; then

        echo "[${SERVICE}] Detaching from role..."
        if aws iam detach-role-policy \
            --role-name "${SERVICE}_secret_manager_role" \
            --policy-arn "$POLICY_ARN"; then

            echo "[${SERVICE}] Deleting policy..."
            if aws iam delete-policy --policy-arn "$POLICY_ARN"; then
                echo "[${SERVICE}] Successfully deleted"
            else
                echo "[${SERVICE}] Failed to delete policy"
            fi
        else
            echo "[${SERVICE}] Failed to detach (might not be attached)"
            echo "[${SERVICE}] Trying direct delete anyway..."
            aws iam delete-policy --policy-arn "$POLICY_ARN" && \
                echo "[${SERVICE}] Deleted without prior detach" || \
                echo "[${SERVICE}] Final deletion failed"
        fi
    else
        echo "[${SERVICE}] Policy does not exist (already deleted?)"
    fi

    echo "---"
done

echo ""
echo "=========================================="
echo "[+] STEP 2: Delete Inline Policies"
echo "=========================================="
aws iam delete-role-policy --role-name jenkins_secret_manager_role --policy-name jenkins_secret_manager_role_policy
aws iam delete-role-policy --role-name ansible_secret_manager_role --policy-name ansible_secret_manager_role_policy
aws iam delete-role-policy --role-name docker_secret_manager_role --policy-name docker_secret_manager_role_policy
aws iam delete-role-policy --role-name tomcat_secret_manager_role --policy-name tomcat_secret_manager_role_policy
aws iam delete-role-policy --role-name nginx_secret_manager_role --policy-name nginx_secret_manager_role_policy
aws iam delete-role-policy --role-name wazuh_dashboard_secret_manager_role --policy-name wazuh_dashboard_secret_manager_role_policy
aws iam delete-role-policy --role-name wazuh_indexer_secret_manager_role --policy-name wazuh_indexer_secret_manager_role_policy
aws iam delete-role-policy --role-name wazuh_server_secret_manager_role --policy-name wazuh_server_secret_manager_role_policy
aws iam delete-role-policy --role-name k8s_secret_manager_role --policy-name k8s_secret_manager_role_policy

echo ""
echo "=========================================="
echo "[+] STEP 3: Remove Role from Instance Profile"
echo "=========================================="
aws iam remove-role-from-instance-profile --instance-profile-name docker_instance_profile --role-name docker_secret_manager_role
aws iam remove-role-from-instance-profile --instance-profile-name ansible_instance_profile --role-name ansible_secret_manager_role
aws iam remove-role-from-instance-profile --instance-profile-name jenkins_instance_profile --role-name jenkins_secret_manager_role
aws iam remove-role-from-instance-profile --instance-profile-name nginx_instance_profile --role-name nginx_secret_manager_role
aws iam remove-role-from-instance-profile --instance-profile-name tomcat_instance_profile --role-name tomcat_secret_manager_role
aws iam remove-role-from-instance-profile --instance-profile-name wazuh_dashboard_instance_profile --role-name wazuh_dashboard_secret_manager_role
aws iam remove-role-from-instance-profile --instance-profile-name wazuh_indexer_instance_profile --role-name wazuh_indexer_secret_manager_role
aws iam remove-role-from-instance-profile --instance-profile-name wazuh_server_instance_profile --role-name wazuh_server_secret_manager_role
aws iam remove-role-from-instance-profile --instance-profile-name k8s_instance_profile --role-name k8s_secret_manager_role

echo ""
echo "=========================================="
echo "[+] STEP 4: Delete Instance Profiles"
echo "=========================================="
aws iam delete-instance-profile --instance-profile-name jenkins_instance_profile
aws iam delete-instance-profile --instance-profile-name ansible_instance_profile
aws iam delete-instance-profile --instance-profile-name docker_instance_profile
aws iam delete-instance-profile --instance-profile-name tomcat_instance_profile
aws iam delete-instance-profile --instance-profile-name nginx_instance_profile
aws iam delete-instance-profile --instance-profile-name wazuh_dashboard_instance_profile
aws iam delete-instance-profile --instance-profile-name wazuh_indexer_instance_profile
aws iam delete-instance-profile --instance-profile-name wazuh_server_instance_profile
aws iam delete-instance-profile --instance-profile-name k8s_instance_profile

echo ""
echo "=========================================="
echo "[+] STEP 5: Delete Roles"
echo "=========================================="
aws iam delete-role --role-name jenkins_secret_manager_role
aws iam delete-role --role-name ansible_secret_manager_role
aws iam delete-role --role-name docker_secret_manager_role
aws iam delete-role --role-name tomcat_secret_manager_role
aws iam delete-role --role-name nginx_secret_manager_role
aws iam delete-role --role-name wazuh_dashboard_secret_manager_role
aws iam delete-role --role-name wazuh_indexer_secret_manager_role
aws iam delete-role --role-name wazuh_server_secret_manager_role
aws iam delete-role --role-name k8s_secret_manager_role

echo ""
echo "=========================================="
echo "[+] Cleanup completed!"
echo "=========================================="
