# VPC of the subnets
data "aws_vpc" "selected" {
  tags = {
    Name = var.vpc_name
    Environment = var.environment
  }
}

# Subnets of the EC2 instances
data "aws_subnets" "service" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    Zone = "public"
  }
}

# Find an official Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] # Canonical official
}

resource "aws_elb" "service" {
  name_prefix   = "${var.service_name}-${var.environment}-"
  security_groups             = [aws_security_group.http.id]
  # subnets                     = data.aws_subnet_ids.
  cross_zone_load_balancing   = true
  internal                    = true
  connection_draining         = true
  connection_draining_timeout = 300

  listener {
    instance_port     = 80
    instance_protocol = "TCP"
    lb_port           = 80
    lb_protocol       = "TCP"
  }

  tags = {
    Name               = "${var.service_name}-${var.environment}"
  }
}

resource "aws_launch_configuration" "service" {
  name_prefix   = "${var.service_name}-${var.environment}-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = var.key_name
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "service" {
  name_prefix   = "${var.service_name}-${var.environment}-"
  launch_configuration      = aws_launch_configuration.service.name
  min_size                  = 2
  max_size                  = 3
  desired_capacity          = "2"
  health_check_type         = "ELB"
  load_balancers            = [aws_elb.service.id]
  termination_policies      = ["OldestLaunchConfiguration"]
  for_each      = toset(data.aws_subnets.service.ids)
  vpc_zone_identifier       = each.value
  wait_for_capacity_timeout = "20m"

  lifecycle {
    create_before_destroy = true
  }
}