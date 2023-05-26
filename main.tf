resource "aws_launch_configuration" "instances_configuration" {
  name_prefix     = "asg-instance"
  image_id        = var.ami
  key_name        = var.key_name
  instance_type   = var.instance_type
  user_data       = file("install_script.sh")
  security_groups = [aws_security_group.instance_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "asg"
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.instances_configuration.name
  vpc_zone_identifier  = [aws_subnet.first_public_subnet.id, aws_subnet.second_public_subnet.id]

  tag {
    key                 = "Name"
    value               = "ASG Instance"
    propagate_at_launch = true
  }
}

resource "aws_lb" "alb" {
  name               = "asg-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.first_public_subnet.id, aws_subnet.second_public_subnet.id]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "asg-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.infrastructure_vpc.id
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.alb_target_group.arn
}

