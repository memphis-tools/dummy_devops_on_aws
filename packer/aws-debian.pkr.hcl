packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.10"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "ami_build_name" {
  type        = string
  description = "Short name of the built AMI"
  default     = env("AMI_BUILD_NAME")
}

variable "ami_prefix" {
  type        = string
  description = "Prefix name of the AMI"
  default     = env("AMI_PREFIX")
}

variable "ami_instance_type" {
  type        = string
  description = "Type of instance to deploy"
  default     = env("AMI_INSTANCE_TYPE")
}

variable "ami_region" {
  type        = string
  description = "AWS region where to deploy the AMI"
  default     = env("AWS_REGION")
  validation {
    condition     = length(var.ami_region) > 0
    error_message = <<EOF
    The aws_region var is not set: make sure to at least set the AWS_DEFAULT_REGION env var.
    To fix this you could also set the aws_region variable from the arguments, for example:
    $ packer build -var=aws_region=us-something-1...
    EOF
  }
}

variable "ami_software_name" {
  type        = string
  description = "AMI short name"
  default     = env("AMI_SOFTWARE_NAME")
}

variable "ami_software_full_name" {
  type        = string
  description = "AMI full name"
  default     = env("AMI_SOFTWARE_FULL_NAME")
}

variable "ami_owner_id" {
  type        = list(string)
  description = "AMI owner id"
  default     = [env("AMI_OWNER_TYPE")]
}

variable "ami_ssh_key_pair_name" {
  type        = string
  description = "AMI SSH key pair's name"
  default     = env("AMI_SSH_KEY_PAIR_NAME")
}

variable "ami_ssh_username" {
  type        = string
  description = "AMI SSH default username"
  default     = env("AMI_SSH_USERNAME")
}

variable "ssh_pubkey_path" {
  type        = string
  description = "Absolute path to the sys-admin's public SSH key to inject into the AMI"
  default     = env("TF_VAR_ssh_pubkey_path")
}

variable "dummy_sysadmin" {
  type    = string
  default = "sysadmin"
}

variable "GRUB_PASSWORD" {
  type        = string
  description = "Grub password"
  default     = env("GRUB_PASSWORD")
}

# origine: source "amazon-ebs" "debian"
source "amazon-ebs" "debian_build" {
  ami_name         = "${var.ami_prefix}-${local.timestamp}"
  instance_type    = var.ami_instance_type
  region           = var.ami_region
  ssh_username     = var.ami_ssh_username
  ssh_keypair_name = var.ami_ssh_key_pair_name
  ssh_agent_auth   = true
  source_ami_filter {
    filters = {
      name                = var.ami_software_full_name
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = var.ami_owner_id
  }
}

build {
  name = var.ami_prefix
  sources = [
    "source.amazon-ebs.debian_build"
  ]

  # ---------------------------
  # Install packages (non-interactive)
  # NB: set the DEBIAN_FRONTEND just to avoid useless warnings
  # ---------------------------
  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y rsync cron tree ca-certificates curl gnupg net-tools dnsutils netcat-traditional ufw rsyslog lynis acct sysstat nftables chkrootkit fail2ban libpam-pwquality libcrack2 apt-show-versions debsums libpam-tmpdir apt-listbugs openssl expect"
    ]
  }

  # ---------------------------
  # Copy the updated /etc/default/grub to instance
  # We add "apparmor=1 security=apparmor audit=1 audit_backlog_limit=8192"
  # Explanation: AppArmor must be enabled at boot time in your bootloader configuration to ensure that the controls it provides are not overridden.
  # ---------------------------
  provisioner "file" {
    source      = "${path.root}/files/grub"
    destination = "/tmp/default_grub"
  }

  # ---------------------------
  # Copy the updated /etc/pam.d/common-password to instance
  # Currently, we already have "password requisite pam_pwquality.so retry=3"
  # We add "password [success=1 default=ignore] pam_unix.so sha512"
  # Explanation: The SHA-512 algorithm provides much stronger hashing than MD5, thus providing additional protection to the system by increasing the level of effort for an attacker to successfully determine passwords. Note that these change only apply to accounts configured on the local system.
  # ---------------------------
  provisioner "file" {
    source      = "${path.root}/files/pamd/common-password"
    destination = "/tmp/pam.d_common-password"
  }

  # ---------------------------
  # Copy the updated /etc/pam.d/common-account to instance
  # We add "account requisite pam_deny.so account required pam_tally2.so"
  # Explanation: Locking out user IDs after n unsuccessful consecutive login attempts mitigates brute force password attacks against your systems.
  # ---------------------------
  provisioner "file" {
    source      = "${path.root}/files/pamd/common-account"
    destination = "/tmp/pam.d_common-account"
  }

  # ---------------------------
  # Copy the updated /etc/pam.d/common-auth to instance
  # We add "auth required pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900"
  # Explanation: Locking out user IDs after n unsuccessful consecutive login attempts mitigates brute force password attacks against your systems.
  # ---------------------------
  provisioner "file" {
    source      = "${path.root}/files/pamd/common-auth"
    destination = "/tmp/pam.d_common-auth"
  }

  # ---------------------------
  # Copy the updated /etc/security/pwquality.conf to instance
  # Currently, we set minlen = 14 and minclass = 4
  # ---------------------------
  provisioner "file" {
    source      = "${path.root}/files/security/pwquality.conf"
    destination = "/tmp/security_pwquality.conf"
  }

  # ---------------------------
  # Copy the updated journald.conf
  # We updated line Storage=persistent
  # ---------------------------
  provisioner "file" {
    source      = "${path.root}/files/journald.conf"
    destination = "/tmp/systemd_journald.conf"
  }

  # ---------------------------
  # Copy the updated login.defs
  # We updated line PASS_MAX_DAYS 365 and PASS_MIN_DAYS	1
  # ---------------------------
  provisioner "file" {
    source      = "${path.root}/files/login.defs"
    destination = "/tmp/login.defs"
  }

  # ----------------------------
  # Users rules
  # ----------------------------
  provisioner "shell" {
    execute_command = "sudo -E bash '{{.Path}}'"
    inline = [
      "useradd -D -f 30"
    ]
  }

  # ---------------------------
  # Move grub, pam.d, security, login.defs on the instance
  # ---------------------------
  provisioner "shell" {
    execute_command = "sudo -E bash '{{.Path}}'"
    inline = [
      "mv /tmp/default_grub /etc/default/grub",
      "mv /tmp/pam.d_common-account /etc/pam.d/common-account",
      "mv /tmp/pam.d_common-auth /etc/pam.d/common-auth",
      "mv /tmp/pam.d_common-password /etc/pam.d/common-password",
      "mv /tmp/security_pwquality.conf /etc/security/pwquality.conf",
      "mv /tmp/systemd_journald.conf /etc/systemd/journald.conf",
      "mv /tmp/login.defs /etc/login.defs"
    ]
  }

  # ---------------------------
  # Copy bashrc, etc_issue, etc_issue_net, sshd_config to instance
  # ---------------------------
  provisioner "file" {
    source      = "${path.root}/files/bashrc"
    destination = "/tmp/bashrc"
  }

  provisioner "file" {
    source      = "${path.root}/files/etc_issue"
    destination = "/tmp/etc_issue"
  }

  provisioner "file" {
    source      = "${path.root}/files/etc_issue_net"
    destination = "/tmp/etc_issue_net"
  }

  provisioner "file" {
    source      = "${path.root}/files/sshd_config"
    destination = "/tmp/sshd_config"
  }

  # ---------------------------
  # Move bashrc to /etc/skel, issue + issue.net to /etc/, and sshd on the instance, remove motd
  # i totally remove motd even if it does not contain any variable relative to the running OS
  # ---------------------------
  provisioner "shell" {
    execute_command = "sudo -E bash '{{.Path}}'"
    inline = [
      "mv /tmp/bashrc /etc/skel/.bashrc",
      "chmod 644 /etc/skel/.bashrc",
      "mv /tmp/etc_issue /etc/issue",
      "mv /tmp/etc_issue_net /etc/issue.net",
      "mv /tmp/sshd_config /etc/ssh/sshd_config",
      "rm /etc/motd"
    ]
  }

  # ---------------------------
  # Ensure we have correct perms
  # ---------------------------
  provisioner "shell" {
    execute_command = "sudo -E bash '{{.Path}}'"
    inline = [
      "chown root:root /boot/grub/grub.cfg",
      "chmod og-rwx /boot/grub/grub.cfg",
      "chown root:root /etc/issue",
      "chown root:root /etc/issue.net",
      "chmod u-x,go-wx /etc/issue",
      "chmod u-x,go-wx /etc/issue.net",
      "chown root:root /etc/cron.hourly/",
      "chmod og-rwx /etc/cron.hourly/",
      "chown root:root /etc/cron.daily/",
      "chmod og-rwx /etc/cron.daily/",
      "chown root:root /etc/cron.weekly/",
      "chmod og-rwx /etc/cron.weekly/",
      "chown root:root /etc/cron.monthly/",
      "chmod og-rwx /etc/cron.monthly/",
      "chown root:root /etc/cron.d/",
      "chmod og-rwx /etc/cron.d/",
      "chown root:root /etc/ssh/sshd_config",
      "chmod og-rwx /etc/ssh/sshd_config",
      "chown root:root /etc/crontab",
      "chmod og-rwx /etc/crontab",
      "chown root:root /etc/login.defs",
      "chmod 0644 /etc/login.defs",
      "chown root:root /etc/pam.d/common-account",
      "chmod 0644 /etc/pam.d/common-account",
      "chown root:root /etc/pam.d/common-auth",
      "chmod 0644 /etc/pam.d/common-auth",
      "chown root:root /etc/pam.d/common-password",
      "chmod 0644 /etc/pam.d/common-password",
      "chown root:root /etc/security/pwquality.conf",
      "chmod 0644 /etc/security/pwquality.conf"
    ]
  }

  provisioner "shell" {
    execute_command = "sudo -E bash '{{.Path}}'"
    inline = [
      "systemctl enable --now sysstat",
      "systemctl enable --now fail2ban",
      "systemctl enable --now rsyslog",
      "systemctl enable --now nftables",
      "cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local",
      "echo 'blacklist cramfs' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist freevxfs' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist jffs2' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist hfs' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist hfsplus' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist udf' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist squashfs' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist usb_storage' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist dccp' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist sctp' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist rds' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist tipc' >> /etc/modprobe.d/blacklist.conf",
      "echo 'blacklist usb-storage' >> /etc/modprobe.d/blacklist.conf",
      "echo 'install pcspkr /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install floppy /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install cramfs /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install freevxfs /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install jffs2 /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install hfs /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install hfsplus /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install udf /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install squashfs /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install usb_storage /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install dccp /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install sctp /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install rds /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install tipc /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
      "echo 'install usb-storage /bin/true' >> /etc/modprobe.d/block_any_load_modules_attemps.conf",
    ]
  }

  # ---------------------------
  # Update initramf and grub, then reboot
  # ---------------------------
  provisioner "shell" {
    execute_command = "sudo -E bash '{{.Path}}'"
    inline = [
      "update-initramfs -u",
      "update-grub",
      "shutdown -r now"
    ]
  }

  # ---------------------------
  # Copy the ssh devops public key to instance (NB: the private key will have no passphrase)
  # ---------------------------
  provisioner "file" {
    source      = var.ssh_pubkey_path
    destination = "/tmp/devops-key.pub"
  }

  # ---------------------------
  # Create OS dummy sys admin user and copy SSH keys
  # ---------------------------
  provisioner "shell" {
    execute_command = "sudo -E bash '{{.Path}}'"
    inline = [
      "useradd -m ${var.dummy_sysadmin} || true",
      "mkdir -p /home/${var.dummy_sysadmin}/.ssh",
      "tee -a /home/${var.ami_ssh_username}/.ssh/authorized_keys < /tmp/devops-key.pub",
      "tee -a /home/${var.dummy_sysadmin}/.ssh/authorized_keys < /tmp/devops-key.pub",
      "chmod 600 /home/${var.dummy_sysadmin}/.ssh/authorized_keys",
      "chown -R ${var.dummy_sysadmin}:${var.dummy_sysadmin} /home/${var.dummy_sysadmin}/.ssh",
      "cp /etc/skel/.bashrc /home/${var.dummy_sysadmin}/.bashrc",
      "chown ${var.dummy_sysadmin}:${var.dummy_sysadmin} /home/${var.dummy_sysadmin}/.bashrc",
      "cp /etc/skel/.bashrc /home/${var.ami_ssh_username}/.bashrc",
      "chown ${var.ami_ssh_username}:${var.ami_ssh_username} /home/${var.ami_ssh_username}/.bashrc"
    ]
  }

  provisioner "shell" {
    execute_command = "sudo -E bash '{{.Path}}'"
    inline = [
      # Ensure new user has bash as login shell
      "chsh -s /bin/bash ${var.dummy_sysadmin}",

      # Update .profile to source .bashrc
      "tee -a /home/${var.dummy_sysadmin}/.profile > /dev/null <<'EOF'",
      "# include .bashrc if it exists",
      "if [ -f \"$HOME/.bashrc\" ]; then",
      "    . \"$HOME/.bashrc\"",
      "fi",
      "EOF",

      # Ensure ownership is correct
      "chown ${var.dummy_sysadmin}:${var.dummy_sysadmin} /home/${var.dummy_sysadmin}/.profile"
    ]
  }

  # ---------------------------
  # Give the dummy sys admin sudo privileges
  # ---------------------------
  provisioner "shell" {
    execute_command = "sudo -E bash '{{.Path}}'"
    inline = [
      "usermod -aG sudo ${var.dummy_sysadmin}",
      "echo '${var.dummy_sysadmin} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${var.dummy_sysadmin}",
      "chmod 440 /etc/sudoers.d/${var.dummy_sysadmin}"
    ]
  }

}
