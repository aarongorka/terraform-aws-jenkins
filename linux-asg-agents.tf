resource "aws_autoscaling_group" "linux-jenkins-agents" {
  count = var.linux_workers ? 1 : 0
  name_prefix               = "${var.tags["Name"]}-linux-jenkins-agents"

  launch_template {
    id      = aws_launch_template.linux-jenkins-agents[0].id
    version = "$Latest"
  }

  vpc_zone_identifier       = var.agents_subnet_ids
  enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  min_size                  = var.agents_min_size
  max_size                  = var.agents_max_size

  tags = [ map("key", "Name", "value", "${var.tags["Name"]}-linux-jenkins-agents", "propagate_at_launch", "true") ]
}

resource "aws_autoscaling_policy" "linux-jenkins-agents-scale-in-policy" {
  count = var.linux_workers ? 1 : 0
  name                   = "${var.tags["Name"]}-linux-jenkins-agents-scale-in-policy"
  autoscaling_group_name = aws_autoscaling_group.linux-jenkins-agents[0].name 
  scaling_adjustment     = "-1"
  adjustment_type        = "ChangeInCapacity"
}
resource "aws_cloudwatch_metric_alarm" "linux-jenkins-agents-scale-in-alarm" {
  count = var.linux_workers ? 1 : 0
  alarm_name          = "${var.tags["Name"]}-linux-jenkins-agents-scale-in"
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
  alarm_actions     = ["${aws_autoscaling_policy.linux-jenkins-agents-scale-in-policy[0].arn}"]
}

resource "aws_autoscaling_policy" "linux-jenkins-agents-scale-out-policy" {
  count = var.linux_workers ? 1 : 0
  name                   = "${var.tags["Name"]}-linux-jenkins-agents-scale-out-policy"
  autoscaling_group_name = aws_autoscaling_group.linux-jenkins-agents[0].name
  scaling_adjustment     = "2"
  adjustment_type        = "ChangeInCapacity"
}
resource "aws_cloudwatch_metric_alarm" "linux-jenkins-agents-scale-out-alarm" {
  count = var.linux_workers ? 1 : 0
  alarm_name          = "${var.tags["Name"]}-linux-jenkins-agents-scale-out"
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
  alarm_actions     = ["${aws_autoscaling_policy.linux-jenkins-agents-scale-out-policy[0].arn}"]
}

resource "aws_launch_template" "linux-jenkins-agents" {
  count = var.linux_workers ? 1 : 0
  name_prefix     = "${var.tags["Name"]}-linux-jenkins-agents"
  image_id        = var.ami_id
  instance_type   = var.agents_instance_type
  vpc_security_group_ids = ["${aws_security_group.linux-jenkins-agents[0].id}"]
  key_name        = var.aws_key_pair_name
  user_data       = base64encode(data.template_file.agents-userdata.rendered)
  iam_instance_profile {
    name = aws_iam_instance_profile.jenkins-master.name
  }

  lifecycle {
    create_before_destroy = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.agents_disk_size
    }
  }

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.agents_spot_price
    }
  }

  tags = var.tags
}

resource "aws_iam_instance_profile" "linux-jenkins-agents" {
  count = var.linux_workers ? 1 : 0
  name = "${var.tags["Name"]}-linux-jenkins-agents"
  role = aws_iam_role.jenkins_role.name
}

resource "aws_security_group" "linux-jenkins-agents" {
  count = var.linux_workers ? 1 : 0
  name   = "${var.tags["Name"]}-linux-jenkins-agents"
  vpc_id = var.vpc_id

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

  tags = var.tags
}
