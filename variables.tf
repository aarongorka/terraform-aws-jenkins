variable "jenkins_unique_id" {
  description = "Unique ID used to identify the EBS volume accross instance terminations"
}

variable "ami_id" {
  description = "AMI ID used by the Jenkins master instance"
  default = "ami-08589eca6dcc9b39c"
}

variable "windows_ami_id" {
  description = "AMI ID used by the Jenkins master instance"
  default = "ami-0bbaefd8648c81cc8"
}

variable "instance_type" {
  description = "Instance type used by Jenkins master instance"
  default = "t3.medium"
}

variable "vpc_id" {
  description = "VPC ID used by the Jenkins master instance"
}

variable "master_subnet_ids" {
  type = list
  description = "Subnet ID for the Jenkins master instance. Multi AZ is supported :)"
}

variable "agents_subnet_ids" {
  type = list
  description = "Subnet IDs for the Jenkins agents."
}

variable "lb_subnet_ids" {
  type = list
  description = "Subnet IDs for the ALB."
}

variable "agents_min_size" {
  description = "Minimum size of agents ASG"
  default = "2"
}

variable "agents_max_size" {
  description = "Max size of agents ASG"
  default = "20"
}

variable "agents_instance_type" {
  description = "Instance type of agents"
  default = "c5.large"
}

variable "agents_disk_size" {
  description = "Size of root volume on Jenkins agents"
  default = "50"
}

variable "agents_spot_price" {
  description = "Max price for spot bids on agents"
  default = "0.5"
}

variable "dns_zone" {
  description = "DNS zone ID used for Jenkins records"
}

variable "dns_base_name" {
  description = "DNS base zone, e.g. example.com"
}

variable "dns_name" {
  description = "DNS record created for Jenkins master in dns_zone"
}

variable "tags" {
  type        = map
  description = "Tags used for all resources except asgs"
}

variable "asg_tags" {
  type = list
  description = "Tags used for ASGs, has an addition attribute propagate_at_launch on every map. Do not include 'Name'."
}

variable "aws_key_pair_name" {
  description = "Keypair for the Jenkins master instance"
}

variable "aws_key_pair_public_key" {
  description = "Public Key in authorized_keys format"
}

variable "master_ebs_root_size" {
  description = "Size of the master EBS root volume"
  default = "20"
}

variable "master_ebs_jenkinshome_size" {
  description = "Size of the master jenkins home volume"
  default = "50"
}

variable "http_proxy" {
  description = "HTTP Proxy used in the Jenkins userdata script"
}

variable "no_proxy" {
  description = "Proxy exceptions used in the Jenkins userdata script"
}

variable "jenkins-cert" {
  description = "ACM Certificate Domain Name for Jenkins"
}

variable "linux_workers" {
  type = bool
  description = "If set to true, enable linux workers"
}

variable "windows_workers" {
  type = bool
  description = "If set to true, enable windows workers"
}

variable "account_name" {
  description = "account name"
}
