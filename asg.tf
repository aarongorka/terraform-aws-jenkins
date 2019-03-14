resource "aws_security_group" "jenkins-master" {
  name   = "${var.tags["Name"]}-jenkins-master"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = ["${aws_security_group.jenkins-master-lb.id}"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 43863
    to_port   = 43863
    protocol  = "tcp"
    security_groups = ["${aws_security_group.jenkins-agents.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"
}

resource "aws_key_pair" "anzcd_infra_jenkins" {
  key_name   = "${var.aws_key_pair_name}"
  public_key = "${var.aws_key_pair_public_key}"
}

resource "aws_iam_instance_profile" "jenkins-master" {
  name = "${var.tags["Name"]}-jenkins-master"
  role = "${aws_iam_role.jenkins_role.name}"
}


resource "aws_launch_template" "jenkins-master" {
  name_prefix            = "${var.tags["Name"]}-jenkins-master-"
  image_id               = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.jenkins-master.id}"]
  key_name               = "${var.aws_key_pair_name}"
  user_data              = "${base64encode(data.template_file.master-userdata.rendered)}"
  iam_instance_profile = {
    name = "${aws_iam_instance_profile.jenkins-master.name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = "${var.master_ebs_root_size}"
    }
  }

  tags = "${var.tags}"
}

resource "aws_autoscaling_group" "jenkins-master" {
  name_prefix               = "${var.tags["Name"]}-jenkins-master-"

  launch_template = {
    id      = "${aws_launch_template.jenkins-master.id}"
    version = "$$Latest"
  }

  vpc_zone_identifier       = ["${var.master_subnet_ids}"]
  enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  target_group_arns         = ["${aws_lb_target_group.jenkins-master-tg.arn}"]
  health_check_type         = "ELB"
  health_check_grace_period = "600"

  tags = "${concat(var.asg_tags, list(map("key", "Name", "value", "${var.tags["Name"]}-jenkins-master", "propagate_at_launch", "true")))}"
}

output "master_ssh" {
  description = "SSH to access the Jenkins master instance"
  value = "ec2-user@${var.dns_name}.${var.dns_base_name}"
}
