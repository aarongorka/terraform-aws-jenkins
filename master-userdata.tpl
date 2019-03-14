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
    }]
}
EOF

# Export proxy variables
export http_proxy=${http_proxy}
export https_proxy=${http_proxy}
export NO_PROXY=${no_proxy}

# Mounting the EBS volume. ebs-pin allows the master to be multi-AZ
pip3 install git+https://github.com/aarongorka/ebs-pin@cf6f670fdffc5dc88cf23817f433eb05f72d06b6 # using an immutable commit hash to ensure it is not changed
/usr/local/bin/ebs-pin attach -u ${jenkins_unique_id}
if ! blkid $(readlink -f /dev/xvdf) | grep ext4; then
    mkfs.ext4 /dev/xvdf
fi
mkdir -p /var/lib/jenkins
mount /dev/xvdf /var/lib/jenkins

# Install docker-compose
curl -sL "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

# Install cli53 from Github. Much nicer syntax than AWS CLI for Route53
curl -sL https://github.com/barnybug/cli53/releases/download/0.8.12/cli53-linux-amd64 -o /usr/bin/cli53
chmod +x /usr/bin/cli53

# Create DNS record pointing to this instance so that agents can connect via JNLP (TCP)
cli53 rrcreate --replace --wait ${dns_base_name} "${dns_name}-master 300 A $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

# Create jenkins user so we can have a fixed UID/GID. Prevents file permission issues on restarts.
groupadd -g 100000 jenkins
useradd -u 100000 -g jenkins -s /bin/false -c "Jenkins Automation Server" -d /var/lib/jenkins jenkins

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key

yum -y install jenkins

chown jenkins:jenkins /var/lib/jenkins

# Allow jenkins and ec2-user to use the docker socket without root privs
usermod -G docker jenkins
usermod -G docker ec2-user

# Start services
systemctl enable docker
systemctl start docker

systemctl enable jenkins
systemctl start jenkins

# Start the jenkins-autoscaler container (https://github.com/aarongorka/docker-jenkins-autoscaler)
export JENKINS_METRICS_PASSWORD=$(aws --region=ap-southeast-2 ssm get-parameters --names "JENKINS_AGENTS_PASSWORD" --with-decryption | jq -r '.["Parameters"][0]["Value"]')  # Prevent password from showing in `ps`
docker run -d --restart=always --net=host -e HTTPS_PROXY=${http_proxy} -e NO_PROXY=${no_proxy} -e JENKINS_METRICS_USERNAME=agents -e JENKINS_METRICS_PASSWORD -e JENKINS_METRICS_MASTER=${dns_name}.${dns_base_name} aarongorka/jenkins-autoscaler:1.0.0
