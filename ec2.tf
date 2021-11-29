
# SSH KEY
resource "aws_key_pair" "main" {
  key_name   = "instance_key"
  public_key = file("ssh.key.pub")

  tags = merge(var.tags, { Name = "instance_key" })
}


# Launch Configuration
resource "aws_launch_template" "main" {
  image_id               = data.aws_ami.al2.id
  instance_type          = "t3a.micro"

  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = aws_key_pair.main.key_name
  user_data              = "${base64encode(data.template_file.script.rendered)}"
  update_default_version = true
  monitoring {
    enabled = false
  }
  
  #instance_market_options {
  #  market_type = "spot"
  #  spot_options {
  #    max_price = "0.5"
  #    spot_instance_type = "one-time"
  #  }
  #}

  credit_specification {
    cpu_credits = "standard"
  }

  tags = merge(var.tags, { Name = "instances" })

  depends_on = [aws_efs_mount_target.efs_pub1, 
                aws_efs_mount_target.efs_pub2, 
                data.aws_secretsmanager_secret_version.db_creds,
                aws_db_instance.db]
}

## ALB
resource "aws_lb" "main" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.sub_pub1.id, aws_subnet.sub_pub2.id]

  enable_deletion_protection = false

  tags = merge(var.tags, { Name = "alb" }) 
}

## TARGET GROUPS
resource "aws_lb_target_group" "main" {
  name     = "instances"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 6
    matcher             = "200-399"
  }

  tags = merge(var.tags, { Name = "instances" }) 
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}


# AutoScaling Group
resource "aws_autoscaling_group" "main" {
  name = "main"
  min_size = 2
  max_size = 2
  vpc_zone_identifier = [aws_subnet.sub_pub1.id, 
                        aws_subnet.sub_pub2.id]
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  #tags = "${merge(var.tags, { Name = "instances" })}"
}

resource "aws_autoscaling_attachment" "main" {
  autoscaling_group_name  = aws_autoscaling_group.main.id
  alb_target_group_arn    = aws_lb_target_group.main.arn
}


#resource "aws_autoscaling_policy" "asg-policy" {
#  name                    = "policy-asg"
#  autoscaling_group_name  = aws_autoscaling_group.main.id
#  policy_type             = "TargetTrackingScaling"
#
#  target_tracking_configuration {
#    predefined_metric_specification {
#      predefined_metric_type = "ASGAverageCPUUtilization"
#    }
#    target_value = 75.0
#  }
#}

#resource "aws_instance" "jump" {
#  ami           = data.aws_ami.al2.id
#  instance_type = "t3a.micro"
#
#  associate_public_ip_address = true
#  vpc_security_group_ids      = [aws_security_group.instance.id]
#  key_name                    = aws_key_pair.main.key_name
#  #user_data                   = data.template_file.script.rendered
#
#  subnet_id = aws_subnet.sub_pub1.id
#
#  credit_specification {
#    cpu_credits = "standard"
#  }
#
#  tags = merge(var.tags, { Name = "jump" })
#
#  depends_on = [aws_efs_mount_target.efs_pub1, 
#                aws_efs_mount_target.efs_pub2, 
#                data.aws_secretsmanager_secret_version.db_creds,
#                aws_db_instance.db]
#}
