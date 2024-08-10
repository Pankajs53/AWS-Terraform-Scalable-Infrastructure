provider "aws" {
  region = "us-east-1"
}


# VPC CREATION  
resource "aws_vpc" "main-vpc" {
  cidr_block = "${var.vpc_cidr}"
  tags = {
    Name = "my-vpc"
  }
}

# PUBLIC SUBNET   
resource "aws_subnet" "public-subnet" {
  count = "${length(var.subnet_cidrs_public)}"
  vpc_id = "${aws_vpc.main-vpc.id}"
  cidr_block = "${var.subnet_cidrs_public[count.index]}"
  availability_zone = "${var.availability_zones[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# PRIVATE SUBNET
resource "aws_subnet" "private-subnet" {
  count = "${length(var.subnet_cidrs_private)}"
  vpc_id = "${aws_vpc.main-vpc.id}"
  cidr_block = "${var.subnet_cidrs_private[count.index]}"
  availability_zone = "${var.availability_zones[count.index]}"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "main"
  }
}

#route table for public subnets
resource "aws_route_table" "main-public" {
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "table-main-public"
  }
}

# route association
resource "aws_route_table_association" "main-public-1" {
  count = "${length(var.subnet_cidrs_public)}"

  subnet_id = "${element(aws_subnet.public-subnet.*.id,count.index)}"
  route_table_id = aws_route_table.main-public.id
}


# route table for private subnets
resource "aws_route_table" "main-private" {
  count = "${length(var.subnet_cidrs_private)}"

  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "table-main-private-${count.index + 1}"
  }
}

resource "aws_route_table_association" "main-pv-1" {
  count = "${length(var.subnet_cidrs_private)}"
  route_table_id = element(aws_route_table.main-private.*.id,count.index)
  subnet_id = element(aws_subnet.private-subnet.*.id,count.index)
}


# security groups
resource "aws_security_group" "allow_tls" {
  name        = "allow-all-sg"
  description = "allow-all-sg"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress  {
    description = "HTTP on port 8000"
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress  {
    description = "HTTP on port 8000"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

# auto scaling group
resource "aws_launch_template" "auto_scale_launch_template" {
  name = "Auto-Scale-Group-Launch-Template"
  key_name = "aws_login2"
  instance_type = "t2.micro"
  image_id  = "ami-04a81a99f5ec58529"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  tags = {
    Name = "AutoScalingGroupTemplate"
  }
  
}

resource "aws_autoscaling_group" "main" {
  name = "Auto-Scaling-Group"
  desired_capacity = 2
  max_size = 4
  min_size = 1
  
  
  launch_template  {
    id = aws_launch_template.auto_scale_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private-subnet[0].id , aws_subnet.private-subnet[1].id]
  
  tag {
    key                 = "Name"
     value               = "Auto-scaling-group-instance"
    propagate_at_launch = true
  }
}


# BIASTIAN SERVER -> EC2 instance
resource "aws_instance" "BaistianServer" {
  ami = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.public-subnet[0].id
  key_name = "aws_login2"
  vpc_security_group_ids  = [aws_security_group.allow_tls.id]

  tags = {
    Name = "Baistian"
  }
}

# LOAD BALANCER
# CREATE TARGET GROUP -> REGISTER TARGET GROUP WITH LOAD BALANCER

#LOAD BALANCER
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_tls.id]
  subnets            = aws_subnet.public-subnet[*].id
  
  enable_deletion_protection = false

  tags = {
    Environment = "dev"
  }
}

# load balancer listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.test.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

# TARGET GROUP
resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main-vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }
}

# auto scaling group attachment with target group
resource "aws_autoscaling_attachment" "asg_target_group" {
  
 autoscaling_group_name = aws_autoscaling_group.main.id
 lb_target_group_arn = aws_lb_target_group.test.arn
}




