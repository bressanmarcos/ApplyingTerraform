provider "aws" {
  profile = "default"
  region = "sa-east-1"
}

resource "aws_s3_bucket" "prod_tf_course" {
  bucket = "tf-course-15111996"
  acl = "private"
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "sa-east-1a"
  tags = {
    "Terraform" : "true"
  }
}  

resource "aws_default_subnet" "default_az2" {
  availability_zone = "sa-east-1b"
  tags = {
    "Terraform" : "true"
  }
}  

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "prod_web" {
  name = "prod_web"
  description = "Allow standard http and https ports inbound and everything outbound"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["168.196.104.179/32"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["168.196.104.179/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_instance" "prod_web" {
  count = 2

  ami = "ami-06aeb70ffb46e1ca0"
  instance_type = "t2.nano"

  vpc_security_group_ids = [
    aws_security_group.prod_web.id
  ]
  
  tags = {
    "Terraform" : "true"
  }
}

resource "aws_elb" "prod_web" {
  name      = "prod-web-loadbalancer"
  subnets = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.prod_web.id]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

resource "aws_launch_template" "prod_web" {
  name_prefix   = "prod-web"
  image_id      = "ami-06aeb70ffb46e1ca0"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "prod_web" {
  # availability_zones = ["sa-east-1a", "sa-east-1b"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]

  launch_template {
    id      = aws_launch_template.prod_web.id
    version = "$Latest"
  }
  tag {
    key =  "Terraform" 
    value = "true"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web.id
}
