module "provider" {
  source = "./modules/provider"
  version = "~>4.0"
  provider-source = "hashicorp/aws"
  bucket-name = "terraform1-assignment"
  bucket-key = "aws/terraform1-assignment/terraform.tfstate"
  region = "us-east-1"
}

# Data source declaration for all necessary fetch
module "aws_vpc" {
  source = "./modules/vpc"
}

module "aws_ami" {
  source = "./modules/ami"
}

/* data "template_file" "nginx_data_script" {
  template = file("./user-data.tpl")
  vars = {
    server = "nginx"
  }
}

data "template_file" "apache_data_script" {
  template = file("./user-data.tpl")
  vars = {
    server = "apache2"
  }
} */


# General Security group declaration
module "aws_security_group" {
  source = "./modules/security-group"
  http-port = 80
  ssh-port = 22
}

# Provision the ec2 instance for APACHE
resource "aws_instance" "apache-server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = "euniceked.pass"
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]
  user_data              = base64encode(data.template_file.apache_data_script.rendered)

  tags = {
    "Name" = "apache-server"
  }
}

# Load balancer, Target Group and ASG Declaration

# Load Balancers and component declaration
resource "aws_lb_target_group" "terraform-tg" {
  name        = "terraform-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    enabled             = true
  }
}

resource "aws_lb" "terraform-lb" {
  name               = "terraform-lb"
  ip_address_type    = "ipv4"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terraform-sg.id]
  subnets            = data.aws_subnets.subnets.ids
}

resource "aws_lb_listener" "terraform-lbl" {
  load_balancer_arn = aws_lb.terraform-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-tg.arn
  }
}

resource "aws_lb_target_group_attachment" "apache-server" {
  target_group_arn = aws_lb_target_group.terraform-tg.arn
  target_id        = aws_instance.apache-server.id
  port             = 80
}

# ASG and component declaretion
resource "aws_launch_template" "nginx-lt" {
  name                   = "nginx-lt"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = "euniceked.pass"
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]
  user_data              = base64encode(data.template_file.nginx_data_script.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name : "nginx-lt"
    }
  }
}

resource "aws_autoscaling_group" "terraform-asg" {
  name                      = "terraform-asg"
  vpc_zone_identifier       = aws_lb.terraform-lb.subnets
  max_size                  = 10
  min_size                  = 2
  desired_capacity          = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.terraform-tg.arn]

  launch_template {
    id      = aws_launch_template.nginx-lt.id
    version = "$Latest"
  }
}
