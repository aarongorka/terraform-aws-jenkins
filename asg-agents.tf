resource "aws_autoscaling_group" "jenkins-agents" {
  name_prefix               = "${var.tags["Name"]}-jenkins-agents-"

  launch_template = {
    id      = "${aws_launch_template.jenkins-agents.id}"
    version = "$$Latest"
  }

  vpc_zone_identifier       = ["${var.agents_subnet_ids}"]
  enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  min_size                  = "${var.agents_min_size}"
  max_size                  = "${var.agents_max_size}"

  tags = "${concat(var.asg_tags, list(map("key", "Name", "value", "${var.tags["Name"]}-jenkins-agents", "propagate_at_launch", "true")))}"
}

resource "aws_autoscaling_policy" "jenkins-agents-scale-in-policy" {
  name                   = "${var.tags["Name"]}-jenkins-agents-scale-in-policy"
  autoscaling_group_name = "${aws_autoscaling_group.jenkins-agents.name}"
  scaling_adjustment     = "-1"
  adjustment_type        = "ChangeInCapacity"
}
resource "aws_cloudwatch_metric_alarm" "jenkins-agents-scale-in-alarm" {
  alarm_name          = "${var.tags["Name"]}-jenkins-agents-scale-in"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "FreeExecutors"
  namespace           = "Jenkins"
  dimensions = {
    JenkinsMaster = "${var.dns_name}.${var.dns_base_name}"
  }
  period              = "60"
  evaluation_periods  = "15"
  statistic           = "Average"
  threshold           = "2"

  alarm_description = "Scale in Jenkins agents"
  alarm_actions     = ["${aws_autoscaling_policy.jenkins-agents-scale-in-policy.arn}"]
}

resource "aws_autoscaling_policy" "jenkins-agents-scale-out-policy" {
  name                   = "${var.tags["Name"]}-jenkins-agents-scale-out-policy"
  autoscaling_group_name = "${aws_autoscaling_group.jenkins-agents.name}"
  scaling_adjustment     = "2"
  adjustment_type        = "ChangeInCapacity"
}
resource "aws_cloudwatch_metric_alarm" "jenkins-agents-scale-out-alarm" {
  alarm_name          = "${var.tags["Name"]}-jenkins-agents-scale-out"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "FreeExecutors"
  namespace           = "Jenkins"
  dimensions = {
    JenkinsMaster = "${var.dns_name}.${var.dns_base_name}"
  }
  period              = "30"
  evaluation_periods  = "1"
  statistic           = "Minimum"
  threshold           = "1"

  alarm_description = "Scale out Jenkins agents"
  alarm_actions     = ["${aws_autoscaling_policy.jenkins-agents-scale-out-policy.arn}"]
}

resource "aws_launch_template" "jenkins-agents" {
  name_prefix     = "${var.tags["Name"]}-jenkins-agents-"
  image_id        = "${var.ami_id}"
  instance_type   = "${var.agents_instance_type}"
  vpc_security_group_ids = ["${aws_security_group.jenkins-agents.id}"]
  key_name        = "${var.aws_key_pair_name}"
  user_data       = "${base64encode(data.template_file.agents-userdata.rendered)}"
  iam_instance_profile = {
    name = "${aws_iam_instance_profile.jenkins-master.name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = "${var.agents_disk_size}"
    }
  }

  instance_market_options {
    market_type = "spot"
    spot_options = {
      max_price = "${var.agents_spot_price}"
    }
  }

  tags = "${var.tags}"
}

resource "aws_iam_instance_profile" "jenkins-agents" {
  name = "${var.tags["Name"]}-jenkins-agents"
  role = "${aws_iam_role.jenkins_role.name}"
}

resource "aws_security_group" "jenkins-agents" {
  name   = "${var.tags["Name"]}-jenkins-agents"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"
}
