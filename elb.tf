resource "aws_elb" "elb" {
  name            = "vault-cluster"
  internal        = "${lookup(var.service_vars, "internal_elb", false)}"
  subnets         = ["${var.public_subnet_ids}"]
  security_groups = ["${var.security_groups}"]

  listener = {
    instance_port      = "8200"
    instance_protocol  = "tcp"
    lb_port            = "8200"
    lb_protocol        = "ssl"
    ssl_certificate_id = "${var.ssl_certificate_id}"
  }

  connection_draining         = true
  connection_draining_timeout = 300

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    timeout             = 3
    target              = "HTTP:8200/v1/sys/health"
    interval            = 5
  }
}
