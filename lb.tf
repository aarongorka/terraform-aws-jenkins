resource "aws_security_group" "jenkins-master-lb" {
  name_prefix = "${var.tags["Name"]}-jenkins-master-lb-"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_lb" "jenkins-master-lb" {
  name               = "${var.tags["Name"]}-jenkins-master-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.jenkins-master-lb.id}"]
  subnets            = ["${var.lb_subnet_ids}"]

  tags = "${var.tags}"
}

resource "aws_lb_listener" "jenkins-master-lb" {
  load_balancer_arn = "${aws_lb.jenkins-master-lb.arn}"
  port            = 80
  protocol        = "HTTP"
  
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_lb_listener" "jenkins-master-lb-https" {
  load_balancer_arn = "${aws_lb.jenkins-master-lb.arn}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.jenkins-cert.arn}"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.jenkins-master-tg.arn}"
  }
}
resource "aws_lb_target_group" "jenkins-master-tg" {
  name        = "${var.tags["Name"]}-jenkins-master-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"

  health_check {
    path = "/whoAmI/"
    matcher = "200,301,302"
  }

  tags = "${var.tags}"
}

resource "aws_route53_record" "jenkins" {
  zone_id = "${var.dns_zone}"
  name    = "${var.dns_name}"
  type    = "A"

  alias {
    name                   = "${aws_lb.jenkins-master-lb.dns_name}"
    zone_id                = "${aws_lb.jenkins-master-lb.zone_id}"
    evaluate_target_health = false
  }
}

output "url" {
  description = "URL to access the Jenkins UI"
  value = "https://${aws_route53_record.jenkins.fqdn}"
}
