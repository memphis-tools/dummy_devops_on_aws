data "aws_vpcs" "k8s" {
  tags = {
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = var.k8s_cluster_name
  }
}

data "aws_eks_cluster" "k8s" {
  name = var.k8s_cluster_name
}

data "aws_vpc" "alb" {
  id = module.tomcat.default_vpc_id
}

data "aws_vpc" "k8s" {
  id = data.aws_vpcs.k8s.ids[0]
}

data "aws_instances" "k8s_nodes" {
  filter {
    name   = "tag:aws:eks:cluster-name"
    values = [var.k8s_cluster_name]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "k8s_node" {
  for_each = toset(data.aws_instances.k8s_nodes.ids)

  instance_id = each.value
}

data "kubernetes_service" "crook_ops" {
  metadata {
    name      = "crook-ops-service"
    namespace = "default"
  }
}

locals {
  k8s_vpc_id     = data.aws_vpcs.k8s.ids[0]
  k8s_subnet_ids = data.aws_eks_cluster.k8s.vpc_config[0].subnet_ids

  k8s_node_ips = data.aws_instances.k8s_nodes.private_ips

  k8s_node_security_group_ids = toset(flatten([
    for node in data.aws_instance.k8s_node :
    node.vpc_security_group_ids
  ]))

  k8s_http_nodeport = one([
    for p in data.kubernetes_service.crook_ops.spec[0].port :
    p.node_port if p.port == 8080
  ])
}

data "aws_route_tables" "k8s" {
  vpc_id = local.k8s_vpc_id

  filter {
    name   = "association.subnet-id"
    values = local.k8s_subnet_ids
  }
}

data "aws_route_tables" "alb" {
  vpc_id = module.tomcat.default_vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_vpc_peering_connection" "alb_to_k8s" {
  vpc_id      = module.tomcat.default_vpc_id
  peer_vpc_id = local.k8s_vpc_id
  auto_accept = true

  tags = {
    Name = "alb-to-${var.k8s_cluster_name}"
  }
}

resource "aws_route" "alb_to_k8s" {
  for_each = toset(data.aws_route_tables.alb.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.k8s.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.alb_to_k8s.id
}

resource "aws_route" "k8s_to_alb" {
  for_each = toset(data.aws_route_tables.k8s.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.alb.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.alb_to_k8s.id
}

resource "aws_lb_target_group" "k8s_http" {
  name_prefix = "k8s-"

  lifecycle {
    create_before_destroy = true
  }
  port        = local.k8s_http_nodeport
  protocol    = "HTTP"
  target_type = "ip"

  vpc_id = module.tomcat.default_vpc_id

  health_check {
    path     = "/crook-ops/"
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "k8s_http" {
  for_each = toset(local.k8s_node_ips)

  target_group_arn  = aws_lb_target_group.k8s_http.arn
  target_id         = each.value
  port              = local.k8s_http_nodeport
  availability_zone = "all"
}

resource "aws_vpc_security_group_ingress_rule" "k8s_http_nodeport" {
  for_each = local.k8s_node_security_group_ids

  security_group_id            = each.value
  referenced_security_group_id = aws_security_group.alb_sg.id

  ip_protocol = "tcp"
  from_port   = local.k8s_http_nodeport
  to_port     = local.k8s_http_nodeport

  description = "Allow ALB to reach Kubernetes HTTP NodePort"

  depends_on = [
    aws_vpc_peering_connection.alb_to_k8s
  ]
}
resource "aws_lb_listener_rule" "k8s_443" {
  listener_arn = aws_lb_listener.https_443.arn
  priority     = 200

  condition {
    path_pattern {
      values = ["/k8s/crook-ops/*"]
    }
  }

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^/k8s/crook-ops/(.*)$"
        replace = "/crook-ops/$1"
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_http.arn
  }
}
