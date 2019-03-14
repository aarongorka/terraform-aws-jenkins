data "template_file" "master-userdata" {
  template = "${file("${path.module}/master-userdata.tpl")}"

  vars = {
    jenkins_unique_id = "${var.jenkins_unique_id}"
    http_proxy = "${var.http_proxy}"
    no_proxy = "${var.no_proxy}"
    dns_base_name = "${var.dns_base_name}"
    dns_name = "${var.dns_name}"

  }
}

data "template_file" "agents-userdata" {
  template = "${file("${path.module}/agents-userdata.tpl")}"

  vars = {
    http_proxy = "${var.http_proxy}"
    no_proxy = "${var.no_proxy}"
    dns_base_name = "${var.dns_base_name}"
    dns_name = "${var.dns_name}"

  }
}
data "aws_acm_certificate" "jenkins-cert" {
  domain   = "${var.jenkins-cert}"
}