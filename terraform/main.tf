provider "aws" {
  region = "us-east-1"
}

# ECS

resource "aws_ecs_cluster" "civicrm" {
  name = "${var.project_name}"
}

resource "aws_ecs_service" "civicrm" {
  name            = "${var.project_name}"
  cluster         = "${aws_ecs_cluster.civicrm.id}"
  task_definition = "${aws_ecs_task_definition.civicrm.arn}"
  desired_count   = 1
  depends_on      = ["aws_iam_role_policy.ecs"]

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${var.aws_region}]"
  }
}

data "template_file" "container_definitions" {
  template = "${file("civicrm_task.json")}"
  vars {
    aws_account_id = "${var.aws_account_id}"
    aws_region = "${var.aws_region}"
    project_name = "${var.project_name}"
  }
}

resource "aws_ecs_task_definition" "civicrm" {
  family = "${var.project_name}"
  requires_compatibilities = ["EC2"]
  container_definitions = "${data.template_file.container_definitions.rendered}"
}

data "aws_ami" "amazon-linux-ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.????????-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "web" {
  ami           = "${data.aws_ami.amazon-linux-ecs.id}"
  instance_type = "t3.micro"
}
