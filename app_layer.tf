# 1. SECURITY GROUPS (ALB & EC2)

# Security Group για τον Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Allow HTTP traffic from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Project-3-ALB-SG" }
}

# Security Group EC2 instances (Web Apps)
resource "aws_security_group" "web_sg" {
  name        = "web-server-security-group"
  description = "Allow traffic ONLY from ALB"
  vpc_id      = aws_vpc.main.id

  # HTTP for ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Project-3-Web-SG" }
}

# APPLICATION LOAD BALANCER

resource "aws_lb" "external_alb" {
  name               = "project-3-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]

  tags = { Name = "Project-3-ALB" }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "project-3-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

# AUTO SCALING GROUP & LAUNCH TEMPLATE

resource "aws_launch_template" "web_template" {
  name_prefix   = "web-server-template-"
  image_id      = "ami-08f44e8eca9095668"
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.web_sg.id]
  }
  
  iam_instance_profile {
    name = aws_iam_instance_profile.web_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -x

              echo "=== Starting User Data ==="

              echo "Checking internet connection..."
              until curl -s --connect-timeout 5 https://www.google.com > /dev/null; do
                echo "Internet not ready yet. Waiting for NAT Gateway... Sleeping 10s"
                sleep 10
              done

              echo "Internet is UP! Proceeding with installation..."

              sudo dnf update -y
              sudo dnf install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd

              echo "<h1>Project-1</h1>" | sudo tee /var/www/html/index.html
              
              echo "=== User Data Finished Successfully ==="
              EOF
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                      = "project-3-web-asg"
  vpc_zone_identifier       = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  target_group_arns         = [aws_lb_target_group.alb_tg.arn]
  health_check_grace_period = 300
  health_check_type         = "ELB"

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Project-3-Web-Server"
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "web-server-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web_profile" {
  name = "web-server-instance-profile"
  role = aws_iam_role.ssm_role.name
}