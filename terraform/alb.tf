resource "aws_security_group" "alb_sg" {
  name        = "crook-ops-alb-sg"
  description = "Allow 80/443/8080/8443 from internet"
  vpc_id      = module.tomcat.default_vpc_id

  dynamic "ingress" {
    for_each = [80, 443, 8080, 8443]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [module.tomcat.default_vpc_id]
  }
}

resource "aws_lb" "crook_ops" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

# --- Target groups (8080 = HTTP, 8443 = HTTPS on the instances) ---
resource "aws_lb_target_group" "tomcat_8080" {
  name     = "tomcat-8080"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.tomcat.default_vpc_id
  health_check { path = "/crook-ops/" }
}

resource "aws_lb_target_group" "tomcat_8443" {
  name             = "tomcat-8443"
  port             = 8443
  protocol         = "HTTPS"
  protocol_version = "HTTP1"
  vpc_id           = module.tomcat.default_vpc_id
  health_check {
    path     = "/crook-ops/"
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group" "docker_8080" {
  name     = "docker-8080"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.tomcat.default_vpc_id
  health_check { path = "/docker/crook-ops/" }
}

resource "aws_lb_target_group" "docker_8443" {
  name             = "docker-8443"
  port             = 8443
  protocol         = "HTTPS"
  protocol_version = "HTTP1"
  vpc_id           = module.tomcat.default_vpc_id
  health_check {
    path     = "/docker/crook-ops/"
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group_attachment" "tomcat_8080" {
  target_group_arn = aws_lb_target_group.tomcat_8080.arn
  target_id        = module.tomcat.tomcat_instance_id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "tomcat_8443" {
  target_group_arn = aws_lb_target_group.tomcat_8443.arn
  target_id        = module.tomcat.tomcat_instance_id
  port             = 8443
}

resource "aws_lb_target_group_attachment" "docker_8080" {
  target_group_arn = aws_lb_target_group.docker_8080.arn
  target_id        = module.docker.docker_instance_id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "docker_8443" {
  target_group_arn = aws_lb_target_group.docker_8443.arn
  target_id        = module.docker.docker_instance_id
  port             = 8443
}

# 8080 plain HTTP
resource "aws_lb_listener" "http_8080" {
  load_balancer_arn = aws_lb.crook_ops.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tomcat_8080.arn
  }
}

# 8443 TLS (terminated at ALB, decrypted, forwarded over HTTPS to instances)
resource "aws_lb_listener" "https_8443" {
  load_balancer_arn = aws_lb.crook_ops.arn
  port              = 8443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.app.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tomcat_8443.arn
  }
}

# 443 (the "real" public URL) and 80 redirect
resource "aws_lb_listener" "https_443" {
  load_balancer_arn = aws_lb.crook_ops.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.app.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tomcat_8080.arn
  }
}

resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.crook_ops.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# --- Path routing: /docker/crook-ops/* → docker, else → tomcat ---
resource "aws_lb_listener_rule" "docker_8080" {
  listener_arn = aws_lb_listener.http_8080.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.docker_8080.arn
  }
  condition {
    path_pattern { values = ["/docker/crook-ops/*"] }
  }
}

resource "aws_lb_listener_rule" "docker_8443" {
  listener_arn = aws_lb_listener.https_8443.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.docker_8443.arn
  }
  condition {
    path_pattern { values = ["/docker/crook-ops/*"] }
  }
}

resource "aws_lb_listener_rule" "docker_443" {
  listener_arn = aws_lb_listener.https_443.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/docker/crook-ops/*"]
    }
  }

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^/docker/crook-ops/(.*)$"
        replace = "/crook-ops/$1"
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.docker_8080.arn
  }
}
