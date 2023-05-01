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


