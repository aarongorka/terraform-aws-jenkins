#!/usr/bin/env bash
set -euo pipefail

# Install Updates and Dependencies from Amazon repositories
amazon-linux-extras install docker
yum update -y
yum -y install java-1.8.0-openjdk make git python3 jq

# Configure Docker (Note: Proxies cannot be set by daemon.json with systemd)
mkdir -p /etc/docker

cat <<EOF >> /etc/sysconfig/docker

http_proxy=${http_proxy}
https_proxy=${http_proxy}
HTTP_PROXY=${http_proxy}
HTTPS_PROXY=${http_proxy}
EOF

cat <<EOF >> /etc/docker/daemon.json
{
    "default-address-pools": [{
        "base":"30.0.0.0/8",
        "size":24
    }],
    "userns-remap": "jenkins"
}
EOF

# Ensure all files created by root inside Docker belong to Jenkins rathern than root. This helps with file permission issue e.g. stashing files.
echo 'jenkins:100000:1' >> /etc/subuid
echo 'jenkins:1000000:65536' >> /etc/subuid
echo 'jenkins:100000:1' >> /etc/subgid
echo 'jenkins:1000000:65536' >> /etc/subgid

cat <<EOF >> /etc/crontab
* 7 * * * root docker system prune -a -f
EOF

# Systemd service that runs the Jenkins agent
cat <<EOF >> /etc/systemd/system/jenkins-agent.service
[Unit]
Description=Jenkins Agent
[Service]
User=jenkins
WorkingDirectory=/var/lib/jenkins
ExecStart=/usr/bin/java -jar /swarm-client.jar -master http://${dns_name}-master.${dns_base_name}:8080 -tunnel ${dns_name}-master.${dns_base_name}:43863 -fsroot /var/lib/jenkins -executors 1 -username agents -passwordEnvVariable JENKINS_AGENTS_PASSWORD
EnvironmentFile=/var/lib/jenkins/systemd.env
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

# Export proxy variables
export http_proxy=${http_proxy}
export https_proxy=${http_proxy}
export NO_PROXY=${no_proxy}

# Install docker-compose
curl -sL "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

# Create jenkins user so we can have a fixed UID/GID. Prevents file permission issues on restarts.
groupadd -g 100000 jenkins
useradd -u 100000 -g jenkins -s /bin/false -c "Jenkins Automation Server" -d /var/lib/jenkins jenkins

# Password required for Jenkins Swarm plugin to connect to the master
echo "JENKINS_AGENTS_PASSWORD=$(aws --region=ap-southeast-2 ssm get-parameters --names "/jenkins/${account_name}/JENKINS_AGENTS_PASSWORD" --with-decryption | jq -r '.["Parameters"][0]["Value"]')" >> /var/lib/jenkins/systemd.env
sudo chmod 0400 /var/lib/jenkins/systemd.env

# Install Jenkins agent
curl -Ls https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.9/swarm-client-3.9.jar -o /swarm-client.jar

chown jenkins:jenkins /var/lib/jenkins

# Allow jenkins and ec2-user to use the docker socket without root privs
usermod -G docker jenkins
usermod -G docker ec2-user

# Start services
systemctl enable docker
systemctl start docker

systemctl daemon-reload
systemctl enable jenkins-agent
systemctl start jenkins-agent