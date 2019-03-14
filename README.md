# Jenkins Terraform Module

A Terraform module that deploys a multi-az master using [ebs-pin][] and a spot ASG for build agents using [Self-Organizing Swarm Plug-in][]. The build agents scale preemtively based on demand using [jenkins-autoscaler][].

[ebs-pin]: https://github.com/aarongorka/ebs-pin
[Self-Organizing Swarm Plug-in]: https://wiki.jenkins.io/display/JENKINS/Swarm+Plugin
[jenkins-autoscaler]: https://github.com/aarongorka/docker-jenkins-autoscaler

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| agents\_disk\_size | Size of root volume on Jenkins agents | string | `"50"` | no |
| agents\_instance\_type | Instance type of agents | string | `"c5.large"` | no |
| agents\_max\_size | Max size of agents ASG | string | `"20"` | no |
| agents\_min\_size | Minimum size of agents ASG | string | `"2"` | no |
| agents\_spot\_price | Max price for spot bids on agents | string | `"0.5"` | no |
| agents\_subnet\_ids | Subnet IDs for the Jenkins agents. | list | n/a | yes |
| ami\_id | AMI ID used by the Jenkins master instance | string | `"ami-08589eca6dcc9b39c"` | no |
| asg\_tags | Tags used for ASGs, has an addition attribute propagate_at_launch on every map. Do not include 'Name'. | list | n/a | yes |
| aws\_key\_pair\_name | Keypair for the Jenkins master instance | string | n/a | yes |
| aws\_key\_pair\_public\_key | Public Key in authorized_keys format | string | n/a | yes |
| dns\_base\_name | DNS base zone, e.g. example.com | string | n/a | yes |
| dns\_name | DNS record created for Jenkins master in dns_zone | string | n/a | yes |
| dns\_zone | DNS zone ID used for Jenkins records | string | n/a | yes |
| http\_proxy | HTTP Proxy used in the Jenkins userdata script | string | n/a | yes |
| instance\_type | Instance type used by Jenkins master instance | string | `"t3.medium"` | no |
| jenkins-cert | ACM Certificate Domain Name for Jenkins | string | n/a | yes |
| jenkins\_unique\_id | Unique ID used to identify the EBS volume accross instance terminations | string | n/a | yes |
| lb\_subnet\_ids | Subnet IDs for the ALB. | list | n/a | yes |
| master\_ebs\_jenkinshome\_size | Size of the master jenkins home volume | string | `"50"` | no |
| master\_ebs\_root\_size | Size of the master EBS root volume | string | `"20"` | no |
| master\_subnet\_ids | Subnet ID for the Jenkins master instance. Multi AZ is supported :) | list | n/a | yes |
| no\_proxy | Proxy exceptions used in the Jenkins userdata script | string | n/a | yes |
| tags | Tags used for all resources except asgs | map | n/a | yes |
| vpc\_id | VPC ID used by the Jenkins master instance | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| master\_ssh | SSH to access the Jenkins master instance |
| url | URL to access the Jenkins UI |

## Manual Steps Required

  1. Go through Jenkins setup, install recommended plugins and configure the proxy if required
  2. Install `Self-Organizing Swarm Plug-in Modules` and Blue Ocean plugin
  3. Enable JNLP port on 43863
  4. Create a local Jenkins service account called "agents" and put password in SSM with the key `JENKINS_AGENTS_PASSWORD`.
  5. Terminate agents and ensure they connect. Set number of build executors on the master to 0 (Manage Jenkins -> Manage Nodes -> Master).
  6. Terminate the master and ensure that it reboots with the correct data, and that metrics from [jenkins-autoscaler][] are being output to CloudWatch Metrics
  7. Configure SCM plugins if required
