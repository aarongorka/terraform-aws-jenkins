resource "aws_iam_role" "jenkins_role" {
  name = "${var.tags["Name"]}-jenkins-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
  EOF
  tags = "${var.tags}"
}

resource "aws_iam_role_policy_attachment" "jenkins_role" {
  role = "${aws_iam_role.jenkins_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
